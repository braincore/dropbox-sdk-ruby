require 'securerandom'

module Dropbox
  module API

    # This class handles the standard OAuth2 flow for web apps.
    class WebAuth
      include Dropbox::API::OAuth2

      CSRF_TOKEN_LENGTH = 20

      # The maximum number of bytes of state kept by the server
      MAX_STATE_LENGTH = 200

      attr_accessor :redirect_uri, :session, :csrf_token_session_key

      # Args:
      # * +app_info+: An AppInfo object with your app's key and secret
      # * +redirect_uri+: The URL to redirect the user to after approving your
      #   app
      # * +session+: An object (like the +session+ hash in Rails) that
      #   represent the current web session. This is used to save the CSRF
      #   token.
      # * +client_identifer+: Your app's user-agent
      # * +csrf_token_session_key+: The key to use in the +session+ object
      # * +locale+: The locale of the user currently using your app
      #   (ex: "en" or "en_US").
      def initialize(app_info, redirect_uri, session, client_identifier = nil,
            csrf_token_session_key = :dropbox_auth_csrf_token, locale = nil)
        oauth2_init(app_info, client_identifier, locale)

        if redirect_uri.nil?
          fail ArgumentError, "No redirect_uri provided. If your app doesn't use a redirect_uri, "\
              " consider using WebAuthNoRedirect for OAuth instead."
        end

        @redirect_uri = redirect_uri
        @session = session
        @csrf_token_session_key = csrf_token_session_key
      end

      # Starts the OAuth 2 authorizaton process, which involves redirecting
      # the user to the returned "authorization URL" (a URL on the Dropbox
      # website).  When the user then either approves or denies your app
      # access, Dropbox will redirect them to the redirect_uri you provided
      # to the constructor, at which point you should call finish() to
      # complete the process.
      #
      # This function will also save a CSRF token to the session and
      # csrf_token_session_key you provided to the constructor. This CSRF
      # token will be checked on finish() to prevent request forgery.
      #
      # Args:
      # * +url_state+: Any data you would like to keep in the URL through the
      #   authorization process.  This exact value will be returned to you by
      #   finish().
      # * +force_reapprove+: If true, forces the user to approve the app again,
      #   even if they already have. Defaults to false.
      #
      # Returns: the URL to redirect the user to
      def start(url_state = nil, force_reapprove = false)
        url_state ||= ''

        max_length = MAX_STATE_LENGTH - CSRF_TOKEN_LENGTH - 1
        unless url_state.length < max_length
          fail ArgumentError, "url_state must be at most #{ max_length } characters"
        end

        # Generate a CSRF token
        # SecureRandom.urlsafe_base64 returns a token longer than specified.
        csrf_token = SecureRandom.urlsafe_base64(CSRF_TOKEN_LENGTH)[0, CSRF_TOKEN_LENGTH]

        state = url_state.empty? ? csrf_token : "#{ csrf_token }|#{ url_state }"
        @session[@csrf_token_session_key] = csrf_token

        params = {
          redirect_uri: @redirect_uri,
          state: state
        }
        params.merge!({ force_reapprove: force_reapprove }) if force_reapprove

        get_authorize_url(params)
      end

      # Call this after the user has visited the authorize URL (see: start()),
      # approved your app, and was redirected to your redirect URI.
      #
      # Args:
      # * +query_params+: The query params on the GET request to your redirect
      #   URI, as a hash.
      #
      # Returns (access_token, user_id, url_state).
      # * +access_token+ can be used to construct a DropboxClient
      # * +user_id+ is the Dropbox user ID of the user that just approved your
      #   app.
      # * +url_state+ is the value you originally passed in to start().
      #
      # Can throw BadRequestError, BadStateError, CsrfError, NotApprovedError,
      # ProviderError, and the standard DropboxError.
      def finish(query_params)
        state = query_params['state']
        error = query_params['error']
        code = query_params['code']
        error_description = query_params['error_description']

        check_request_wellformed(state, error, code)
        url_state = check_csrf_token(state)
        check_errors(error, error_description)

        # If everything went ok, make the request to get an access token
        access_token, user_id = get_token(code, redirect_uri: @redirect_uri)
        return access_token, user_id, url_state
      end

      private

      # A string comparison function that is resistant to timing attacks.
      # If you're comparing a string you got from the outside world with a
      # string that is supposed to be a secret, use this function to check
      # equality.
      def safe_string_equals(a, b)
        a.length == b.length && a.chars.zip(b.chars).map {
          |ac, bc| ac == bc
        }.all?
      end

      def check_request_wellformed(state, error, code)
        if state.nil?
          fail BadRequestError,
              'Missing query parameter "state".'
        end
        if (!error.nil? && !code.nil?) || (error.nil? && code.nil?)
          fail BadRequestError,
              'Exactly one of params "code" and "error" must be set.'
        end
      end

      def check_csrf_token(state)
        session_token = @session[@csrf_token_session_key]

        if session_token.nil?
          fail BadStateError, 'Missing CSRF token in session.'
        end
        if session_token.length != CSRF_TOKEN_LENGTH
          fail "CSRF token not correct length: #{ session_token.inspect }"
        end

        split_pos = state.index('|')
        if split_pos.nil?
          given_csrf_token = state
          url_state = nil
        else
          given_csrf_token, url_state = state.split('|', 2)
        end

        unless safe_string_equals(session_token, given_csrf_token)
          fail CsrfError, "Expected #{ session_token.inspect };"\
              " got #{ given_csrf_token.inspect }."
        end

        @session.delete(@csrf_token_session_key)
        url_state
      end

      def check_errors(error, description)
        return if error.nil?

        if error == 'access_denied'
          # The user clicked "Deny"
          if description.nil?
            fail NotApprovedError, 'No additional description from Dropbox.'
          else
            fail NotApprovedError, "Additional description from Dropbox: "\
                " #{ description }"
          end
        elsif description.nil?
          fail ProviderError, error
        else
          fail ProviderError, "#{ error }: #{ description }"
        end
      end

      # Thrown if the redirect URL was missing parameters or if the given
      # parameters were not valid.
      #
      # The recommended action is to show an HTTP 400 error page.
      class BadRequestError < RuntimeError; end

      # Thrown if all the parameters are correct, but there's no CSRF token in
      # the session. This probably means that the session expired.
      #
      # The recommended action is to redirect the user's browser to try the
      # approval process again.
      class BadStateError < RuntimeError; end

      # Thrown if the given 'state' parameter doesn't contain the CSRF token
      # from the user's session. This is blocked to prevent CSRF attacks.
      #
      # The recommended action is to respond with an HTTP 403 error page.
      class CsrfError < RuntimeError; end

      # The user chose not to approve your app.
      class NotApprovedError < RuntimeError; end

      # Dropbox redirected to your redirect URI with some unexpected error
      # identifier and error message.
      class ProviderError < RuntimeError; end

    end

  end
end