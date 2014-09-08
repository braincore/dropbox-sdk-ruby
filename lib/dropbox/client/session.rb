module Dropbox
  module API

    # This class handles making requests for the Dropbox::API::Client class.
    class Session

      def initialize(oauth2_token, client_identifier, locale, host_info)
        @client_identifier = client_identifier
        @host_info = host_info
        @common_headers = {
          'Authorization' => "Bearer #{ oauth2_token }",
          'Dropbox-API-User-Locale' => locale
        }
      end

      def do_rpc_endpoint(path, args)
        Dropbox::API::HTTP.do_http_request(
            Net::HTTP::Post, @host_info.api_server, path,
            client_identifier: @client_identifier,
            headers: @common_headers,
            body: args,
            port: @host_info.port)
      end

      def do_content_endpoint(path, args, data = nil)
        headers = @common_headers.merge({
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