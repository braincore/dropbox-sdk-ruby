module Dropbox
  module API
    class HostInfo

      attr_reader :web_server, :api_server, :api_content_server

      def initialize(web_server = nil, api_server = nil, api_content_server = nil)
        @web_server = web_server || Dropbox::API::WEB_SERVER
        @api_server = api_server || Dropbox::API::API_SERVER
        @api_content_server = api_content_server || Dropbox::API::API_CONTENT_SERVER
      end

      def self.default
        @@default ||= self.new
      end

    end
  end
end