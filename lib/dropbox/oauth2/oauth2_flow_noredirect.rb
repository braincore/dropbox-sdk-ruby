module Dropbox
  module API

    class OAuth2FlowNoRedirect < OAuth2FlowBase

      def initialize(app_key, app_secret, locale = nil)
        super(app_key, app_secret, locale)
      end

      def start
        get_authorize_url
      end

      def finish(code)
        get_token(code, nil)
      end

    end

  end
end