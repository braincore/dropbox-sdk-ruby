module Dropbox
  module API
    class AppInfo

      attr_accessor :key, :secret, :host_info

      def initialize(app_key, app_secret, host_info = nil)
        @key = app_key
        @secret = app_secret
        @host_info = host_info || Dropbox::API::HostInfo.default
      end

      def self.from_json_file(filename)
        file = ::File.open(filename, 'r')
        contents = file.read
        file.close

        json = Oj.load(contents)
        self.from_json(json)
      end

      def self.from_json(json)
        unless json.include?('app_key') && json.include?('app_secret')
          fail 'JSON must have fields "app_key" and "app_secret"'
        end

        if json.include?('web_server') ||
           json.include?('api_server') ||
           json.include?('api_content_server') ||
           json.include?('port')
          host_info = Dropbox::API::HostInfo.from_json(json)
        else
          host_info = Dropbox::API::HostInfo.default
        end

        self.new(json['app_key'], json['app_secret'], host_info)
      end

    end
  end
end
