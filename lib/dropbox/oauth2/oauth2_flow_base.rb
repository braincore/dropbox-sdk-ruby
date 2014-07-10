require 'uri'

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
        
        @app_key = app_key
        @app_secret = app_secret
        @locale = locale
      end

      private

      # TODO this is the one part of the client that returns a URL instead of actually making the request. darn
      def get_authorize_url(other_params = {})
        params = {
          'client_id' => @app_key,
          'response_type' => 'code',
          'locale' => @locale
        }.merge(other_params)

        host = Dropbox::API::WEB_SERVER
        path = "/#{ Dropbox::API_VERSION }/oauth2/authorize"
        params = Dropbox::API::HTTP::make_query_string(params)

        "https://#{ host }#{ path }?#{ params }"
      end

      def get_token(code, other_params = {})
        if not code.is_a?(String)
          fail ArgumentError, "code must be a String; got #{ code.inspect }"
        end

        client_credentials = "#{ @app_key }:#{ @app_secret }"

        method = Net::HTTP::Post
        host = Dropbox::API::API_SERVER
        path = '/oauth2/token'
        params = {}
        headers = {
          'Authorization' => "Basic #{ Base64.encode64(client_credentials).chomp("\n") }"
        }
        body_params = {
          'grant_type' => 'authorization_code',
          'locale' => @locale,
        }.merge(other_params)

        response = Dropbox::API::HTTP::do_http_request(method, host, path, params, headers, body_params)

        json = Dropbox::parse_response(response)
        ["token_type", "access_token", "uid"].each { |k|
          if not json.has_key?(k)
            raise DropboxError.new("Bad response from /token: missing \"#{k}\".")
          end
          if not json[k].is_a?(String)
            raise DropboxError.new("Bad response from /token: field \"#{k}\" is not a string.")
          end
        }
        if json["token_type"] != "bearer" and json["token_type"] != "Bearer"
          raise DropboxError.new("Bad response from /token: \"token_type\" is \"#{token_type}\".")
        end

        return json['access_token'], json['uid']
      end

    end

  end
end