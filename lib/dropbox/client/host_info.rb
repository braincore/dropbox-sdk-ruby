module Dropbox
  module API

    # This class stores host information to be able to configure which hosts
    # the SDK connects to. All of them will default to the real Dropbox
    # servers.
    class HostInfo

      attr_accessor :web_server, :api_server, :api_content_server, :port

      def initialize(web_server = nil,
                     api_server = nil,
                     api_content_server = nil,
                     port = nil)
        @web_server = web_server || WEB_SERVER
        @api_server = api_server || API_SERVER
        @api_content_server = api_content_server || API_CONTENT_SERVER
        @port = port || Dropbox::API::HTTP::HTTPS_PORT
      end

      # Get an instance that contains all the default hosts.
      def self.default
        @@default ||= self.new
      end

      def self.from_json(json)
        self.new(json['web_server'],
                 json['api_server'],
                 json['api_content_server'],
                 json['port'])
      end

      def self.from_json_file(filename)
        file = File.open(filename, 'r')
        contents = file.read
        file.close

        json = Oj.load(contents)
        self.from_json(json)
      end

    end
  end
end