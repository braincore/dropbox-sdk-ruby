module Dropbox
  module API

    class Session

      def initialize(oauth2_token, client_identifier, locale, host_info)
        @client_identifier = client_identifier
        @host_info = host_info
        @COMMON_HEADERS = {
          'Authorization' => "Bearer #{ oauth2_token }",
          'Dropbox-API-User-Locale' => locale
        }
      end

      def do_rpc_endpoint(path, args)
        Dropbox::API::HTTP.do_http_request(
            Net::HTTP::Post, @host_info.api_server, path,
            client_identifier: @client_identifier,
            headers: @COMMON_HEADERS,
            body: args,
            port: @host_info.port)
      end

      # TODO Check if I can hardcode POST
      def do_content_endpoint(path, args, data = nil)
        headers = @COMMON_HEADERS.merge({
          'Dropbox-API-Args' => Oj.dump(args)
        })
        Dropbox::API::HTTP.do_http_request(
            Net::HTTP::Post, @host_info.api_content_server, path,
            client_identifier: @client_identifier,
            headers: headers,
            body: data,
            port: @host_info.port)
      end
    end

  end
end