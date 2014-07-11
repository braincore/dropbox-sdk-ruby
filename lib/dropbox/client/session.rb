module Dropbox
  module API

    class Session

      def initialize(oauth2_access_token, locale)
        @oauth2_token = oauth2_access_token
        @locale = locale
      end

      def do_get(host, path, params = {}, headers = {})  # :nodoc:
        sign_and_set_locale(params, headers)
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Get, host, path, params, headers)
      end

      def do_post(host, path, params = {}, headers = {})  # :nodoc:
        sign_and_set_locale(params, headers)
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Post, host, path, nil, headers, params)
      end

      def do_put(host, path, params = {}, headers = {}, body = nil)  # :nodoc:
        sign_and_set_locale(params, headers)
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Put, host, path, params, headers, body)
      end

      private

      def sign_and_set_locale(params, headers)
        params['locale'] = @locale
        headers['Authorization'] = "Bearer #{ @access_token }"
      end

    end

  end
end