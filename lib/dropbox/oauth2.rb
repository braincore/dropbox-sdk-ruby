require 'base64'

module Dropbox
  module API

    # This module contains OAuth2 functions for the authorization
    # flow. The Ruby SDK does not support the token flow. You should use
    # either the WebAuth or WebAuthNoRedirect classes.
    module OAuth2

      attr_accessor :app_key, :app_secret, :locale, :client_identifier

      def oauth2_init(app_info, client_identifier = nil, locale = nil)
        @app_key = app_info.key
        @app_secret = app_info.secret
        @host_info = app_info.host_info
        @client_identifier = client_identifier || ''
        @locale = locale
      end

      private

      def get_authorize_url(other_params = {})
        params = {
          'client_id' => @app_key,
          'response_type' => 'code',
          'locale' => @locale
        }.merge(other_params)

        host = @host_info.web_server
        path = "/#{ API_VERSION }/oauth2/authorize"
        params = Dropbox::API::HTTP.make_query_string(params)

        "https://#{ host }#{ path }?#{ params }"
      end

      def get_token(code, other_params = {})
        client_credentials = "#{ @app_key }:#{ @app_secret }"

        method = Net::HTTP::Post
        host = @host_info.api_server
        path = '/oauth2/token'
        headers = {
          'Authorization' => "Basic #{ Base64.encode64(client_credentials).chomp("\n") }"
        }
        params = {
          'grant_type' => 'authorization_code',
          'code' => code,
          'locale' => @locale,
        }.merge(other_params)

        response = Dropbox::API::HTTP.do_http_request(
            method,
            host,
            path,
            client_identifier: @client_identifier,
            headers: headers,
            params: params,
            port: @host_info.port)
        json = Dropbox::API::HTTP.parse_response(response)

        ['token_type', 'access_token', 'uid'].each do |key|
          unless json.has_key?(key)
            fail DropboxError.new("Bad response from /token: missing field \"#{ key }\"")
          end
          unless json[key].is_a?(String)
            fail DropboxError.new("Bad response from /token: field \"#{ key }\" "\
                "should be a String; got #{ json[key].inspect }")
          end
        end

        unless json['token_type'].downcase == 'bearer'
          fail DropboxError.new("Bad response from /token: \"token_type\" must be \"bearer\"; "\
              "got \"#{ json['token_type'] }\"")
        end

        return json['access_token'], json['uid']
      end

    end

  end
end