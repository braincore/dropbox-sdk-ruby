module Dropbox
  module API

    class OAuth2FlowBase

      AUTHORIZE_HOST = "https://#{ DROPBOX::API::WEB_SERVER }"
      AUTHORIZE_PATH = "/#{ DROPBOX::API::API_VERSION }/oauth2/authorize"
      TOKEN_HOST = "https://#{ DROPBOX::API::API_SERVER }"
      TOKEN_PATH = "/#{ DROPBOX::API::API_VERSION }/oauth2/authorize"

      def initialize(app_key, app_secret, locale = nil)
        unless app_key.is_a?(String)
          fail ArgumentError, "app_key must be a String; got #{ app_key.inspect }"
        end
        unless app_secret.is_a?(String)
          fail ArgumentError, "app_secret must be a String; got #{ app_secret.inspect }"
        end
        
        @locale = locale

        ssl_options = { use_ssl: true,
                        verify_mode: OpenSSL::SSL::VERIFY_PEER,
                        ca_file: Dropbox::API::TRUSTED_CERT_FILE

                        # Important security note!
                        # Some Ruby versions (e.g. the one that ships with OS X) do not raise an exception if certificate validation fails.
                        # We therefore have to add a custom callback to ensure that invalid certs are not accepted
                        # See https://www.braintreepayments.com/braintrust/sslsocket-verify_mode-doesnt-verify
                        # You can comment out this code in case your Ruby version is not vulnerable
                        verify_callback: proc do |preverify_ok, ssl_context|
                          Dropbox::verify_ssl_certificate(preverify_ok, ssl_context)
                        end 
                      }

        if RUBY_VERSION >= '1.9'
          ssl_options[:ssl_version] = 'TLSv1'
          ssl_options[:ciphers] =
            'ECDHE-RSA-AES256-GCM-SHA384:'\
            'ECDHE-RSA-AES256-SHA384:'\
            'ECDHE-RSA-AES256-SHA:'\
            'ECDHE-RSA-AES128-GCM-SHA256:'\
            'ECDHE-RSA-AES128-SHA256:'\
            'ECDHE-RSA-AES128-SHA:'\
            'ECDHE-RSA-RC4-SHA:'\
            'DHE-RSA-AES256-GCM-SHA384:'\
            'DHE-RSA-AES256-SHA256:'\
            'DHE-RSA-AES256-SHA:'\
            'DHE-RSA-AES128-GCM-SHA256:'\
            'DHE-RSA-AES128-SHA256:'\
            'DHE-RSA-AES128-SHA:'\
            'AES256-GCM-SHA384:'\
            'AES256-SHA256:'\
            'AES256-SHA:'\
            'AES128-GCM-SHA256:'\
            'AES128-SHA256:'\
            'AES128-SHA'
        end

        # Exclude site parameter because it depends on which path we're going to
        @oauth2_client = OAuth2::Client.new(app_key, 
                                            app_secret, 
                                            authorize_url: AUTHORIZE_PATH, 
                                            token_url: TOKEN_PATH,
                                            ssl: ssl_options)
      end

      private

      def get_authorize_url(params = {})
        @oauth2_client.site = AUTHORIZE_HOST
        @oauth2_client.auth_code.authorize_url(Dropbox::API::Util::clean_params({ locale: @locale }.merge(params)))
      end

      def get_token(code, redirect_uri)
        @oauth2_client.site = TOKEN_HOST
        @oauth2_client.auth_code.get_token(code, Dropxbox::API::Util::clean_params({ 
          redirect_uri: redirect_uri, 
          locale: @locale, 
          headers: { 'User-Agent': => "OfficialDropboxRubySDK/#{Dropbox::API::SDK_VERSION}" } 
        })
      end

    end

  end
end