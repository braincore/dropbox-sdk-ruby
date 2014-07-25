module Dropbox
  module API

    class Session

      def initialize(oauth2_access_token, client_identifier, locale)
        @oauth2_access_token = oauth2_access_token
        @client_identifier = client_identifier
        @locale = locale
      end

      def do_get(host, path, params = {}, headers = {})  # :nodoc:
        sign_and_set_locale(params, headers)
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Get, host, path, @client_identifier, params, headers)
      end

      def do_post(host, path, params = {}, headers = {})  # :nodoc:
        sign_and_set_locale(params, headers)
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Post, host, path, @client_identifier, nil, headers, params)
      end

      def do_put(host, path, params = {}, headers = {}, body = nil)  # :nodoc:
        sign_and_set_locale(params, headers)
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Put, host, path, @client_identifier, params, headers, body)
      end

      private

      def sign_and_set_locale(params, headers)
        params['locale'] = @locale
        headers['Authorization'] = "Bearer #{ @oauth2_access_token }"
      end

    end

  end
end