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

      def self.from_json(json)
        @web_server = json['web_server']
        @api_server = json['api_server']
        @api_content_server = json['api_content_server']
      end

      def self.from_json_file(filename)
        file = File.open(filename, 'r')
        contents = file.read
        file.close

        json = MultiJson.load(contents)
        self.from_json(json)
      end

    end
  end
end