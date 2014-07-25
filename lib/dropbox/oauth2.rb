require 'uri'
require 'base64'

module Dropbox
  module API

    # This module contains OAuth2 functions for the authorization
    # flow. The Ruby SDK does not support the token flow. You should use
    # either the WebAuth or WebAuthNoRedirect classes.
    module OAuth2

      # TODO add other common methods from PHP doc?

      attr_reader :app_key, :app_secret, :locale, :client_identifier

      def oauth2_init(app_info, client_identifier, locale = nil)
        unless app_info.key.is_a?(String)
          fail ArgumentError, "app_key must be a String; got #{ app_key.inspect }"
        end
        unless app_info.secret.is_a?(String)
          fail ArgumentError, "app_secret must be a String; got #{ app_secret.inspect }"
        end

        @app_key = app_info.key
        @app_secret = app_info.secret
        @host_info = app_info.host_info
        @client_identifier = client_identifier
        @locale = locale
      end

      private

      # TODO this is the one part of the entire SDK that returns a URL instead of actually making the request. darn
      def get_authorize_url(other_params = {})
        params = {
          'client_id' => @app_key,
          'response_type' => 'code',
          'locale' => @locale
        }.merge(other_params)

        host = @host_info.web_server
        path = "/#{ Dropbox::API::API_VERSION }/oauth2/authorize"
        params = Dropbox::API::HTTP.make_query_string(params)

        "https://#{ host }#{ path }?#{ params }"
      end

      def get_token(code, other_params = {})
        if not code.is_a?(String)
          fail ArgumentError, "code must be a String; got #{ code.inspect }"
        end

        client_credentials = "#{ @app_key }:#{ @app_secret }"

        method = Net::HTTP::Post
        host = @host_info.api_server
        path = '/oauth2/token'
        params = {}
        headers = {
          'Authorization' => "Basic #{ Base64.encode64(client_credentials).chomp("\n") }"
        }
        body_params = {
          'grant_type' => 'authorization_code',
          'code' => code,
          'locale' => @locale,
        }.merge(other_params)

        response = Dropbox::API::HTTP.do_http_request(method, host, path, client_identifier, params, headers, body_params)
        json = Dropbox::API::HTTP.parse_response(response)

        ['token_type', 'access_token', 'uid'].each do |key|
          unless json.has_key?(key)
            fail DropboxError.new("Bad response from /token: missing field \"#{ key }\"")
          end
          unless json[key].is_a?(String)
            fail DropboxError.new("Bad response from /token: field \"#{ key }\" must be a String; got #{ json[key].inspect }")
          end
        end

        unless json['token_type'].downcase == 'bearer'
          fail DropboxError.new("Bad response from /token: \"token_type\" must be \"bearer\"; got \"#{ json['token_type'] }\"")
        end

        return json['access_token'], json['uid']
      end

    end

  end
end