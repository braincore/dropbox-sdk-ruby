require 'securerandom'

module Dropbox
  module API

    class WebAuth
      include Dropbox::API::OAuth2

      # TODO put errors in their own file?

      # Thrown if the redirect URL was missing parameters or if the given parameters were not valid.
      #
      # The recommended action is to show an HTTP 400 error page.
      class BadRequestError < Exception; end

      # Thrown if all the parameters are correct, but there's no CSRF token in the session.  This
      # probably means that the session expired.
      #
      # The recommended action is to redirect the user's browser to try the approval process again.
      class BadStateError < Exception; end

      # Thrown if the given 'state' parameter doesn't contain the CSRF token from the user's session.
      # This is blocked to prevent CSRF attacks.
      #
      # The recommended action is to respond with an HTTP 403 error page.
      class CsrfError < Exception; end

      # The user chose not to approve your app.
      class NotApprovedError < Exception; end

      # Dropbox redirected to your redirect URI with some unexpected error identifier and error
      # message.
      class ProviderError < Exception; end

      CSRF_TOKEN_LENGTH = 20
      MAX_STATE_LENGTH = 200

      def initialize(app_key, app_secret, redirect_uri, session, csrf_token_session_key = :dropbox_auth_csrf_token, locale = nil)
        oauth2_init(app_key, app_secret, locale)
        
        unless redirect_uri.is_a?(String)
          fail ArgumentError, "redirect_uri must be a String; got #{ redirect_uri.inspect }"
        end

        # TODO check redirect_uri for localhost/https? [nope?]
        # TODO add force_reapprove and disable_signup params?

        @redirect_uri = redirect_uri
        @session = session
        @csrf_token_session_key = csrf_token_session_key
      end

      def start(url_state = nil)
        # If url_state is provided, it must be a string
        url_state ||= ''
        unless url_state.is_a?(String)
          fail ArgumentError, "url_state must be a String; got #{ url_state.inspect }"
        end

        # API only guarantees 200 bytes of state?
        # This error check looks super arbitrary...
        # Rely on server-side check instead?
        max_length = MAX_STATE_LENGTH - CSRF_TOKEN_LENGTH - 1
        unless url_state.length < max_length
          fail ArgumentError, "url_state must be at most #{ max_length } characters"
        end

        # Generate a CSRF token
        # Currently 120 bits of entropy
        # SecureRandom.urlsafe_base64 doesn't actually return a token of the specified length
        csrf_token = SecureRandom.urlsafe_base64(CSRF_TOKEN_LENGTH)[0, CSRF_TOKEN_LENGTH]

        state = url_state.empty? ? csrf_token : "#{ csrf_token }|#{ url_state }"
        @session[@csrf_token_session_key] = csrf_token

        get_authorize_url(redirect_uri: @redirect_uri, state: state)
      end

      def finish(query_params)

        state = query_params['state']
        error = query_params['error']
        code = query_params['code']
        error_description = query_params['error_description']

        check_request_wellformed(state, error, code)
        url_state = check_csrf_token(state)
        check_errors(error, error_description)     

        # If everything went ok, make the network call to get an access token
        access_token, user_id = get_token(code, redirect_uri: @redirect_uri)
        return access_token, user_id, url_state
      end

      private

      def safe_string_equals(a, b)
        a.length == b.length && a.chars.zip(b.chars).map { |ac, bc| ac == bc }.all?
      end

      def check_request_wellformed(state, error, code)
        if state.nil?
          fail BadRequestError, 'Missing query parameter "state".'
        end
        if !error.nil? && !code.nil?
          fail BadRequestError, 'Query parameters "code" and "error" are both set;' \
                        ' only one must be set.'
        end
        if error.nil? && code.nil?
          fail BadRequestError, 'Neither query parameter "code" or "error" is set.'
        end
      end

      def check_csrf_token(state)
        csrf_token_from_session = @session[@csrf_token_session_key]

        if csrf_token_from_session.nil?
          fail BadStateError, 'Missing CSRF token in session.'
        end
        if csrf_token_from_session.length != CSRF_TOKEN_LENGTH
          fail BadRequestError, "CSRF token not correct length: #{ csrf_token_from_session.inspect }"
        end

        split_pos = state.index('|')
        if split_pos.nil?
          given_csrf_token = state
          url_state = nil
        else
          given_csrf_token, url_state = state.split('|', 2)
        end

        unless safe_string_equals(csrf_token_from_session, given_csrf_token)
          fail CsrfError, "Expected #{ csrf_token_from_session.inspect }; " \
                      "got #{ given_csrf_token.inspect }."
        end

        @session.delete(@csrf_token_session_key)
        url_state
      end

      def check_errors(error, error_description)
        unless error.nil?
          if error == 'access_denied'
            # The user clicked "Deny"
            if error_description.nil?
              fail NotApprovedError, 'No additional description from Dropbox.'
            else
              fail NotApprovedError, "Additional description from Dropbox: #{ error_description }"
            end
          else
            # All other errors.
            full_message = error_description.nil? ? error : "#{ error }: #{ error_description }"
            fail ProviderError, full_message
          end
        end
      end

    end

  end
end