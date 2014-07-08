require 'securerandom'

module Dropbox
  module API

    class OAuth2Flow < OAuth2FlowBase

      CSRF_TOKEN_LENGTH = 20
      MAX_STATE_LENGTH = 200

      def initialize(app_key, app_secret, redirect_uri, session, csrf_token_session_key = :dropbox_auth_csrf_token, locale = nil)
        super(app_key, app_secret, locale)
        unless redirect_uri.is_a?(String)
          fail ArgumentError, "redirect_uri must be a String; got #{ redirect_uri.inspect }"
        end

        @redirect_uri = redirect_uri
        @session = session
        @csrf_token_session_key = csrf_token_session_key
      end

      def start(url_state = nil)
        url_state ||= ''
        unless url_state.is_a?(String)
          fail ArgumentError, "url_state must be a String; got #{ url_state.inspect }"
        end

        # API only guarantees 200 bytes of state?
        # This error check looks super arbitrary...
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
        # get_token(code, @redirect_uri)
      end

    end

  end
end