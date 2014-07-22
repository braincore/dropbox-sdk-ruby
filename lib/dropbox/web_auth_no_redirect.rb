module Dropbox
  module API

    class WebAuthNoRedirect
      include Dropbox::API::OAuth2

      def initialize(app_info, client_identifier, locale = nil)
        oauth2_init(app_info, client_identifier, locale)
      end

      def start
        get_authorize_url
      end

      def finish(code)
        get_token(code)
      end

    end

  end
end