module Dropbox
  module API

    class WebAuthNoRedirect
      include Dropbox::API::OAuth2

      def initialize(app_key, app_secret, locale = nil)
        oauth2_init(app_key, app_secret, locale)
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