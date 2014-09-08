module Dropbox
  module API

    # OAuth 2 authorization helper for apps that can't provide a
    # redirect URI (such as the command line example apps).
    class WebAuthNoRedirect
      include Dropbox::API::OAuth2

      # Args:
      # * +app_info+: An AppInfo object with your app's key and secret
      # * +client_identifer+: Your app's user-agent
      # * +locale+: The locale of the user currently using your app
      #   (ex: "en" or "en_US").
      def initialize(app_info, client_identifier = nil, locale = nil)
        oauth2_init(app_info, client_identifier, locale)
      end

      # Returns a authorization_url, which is a page on Dropbox's website.
      # Have the user visit this URL and approve your app.
      def start
        get_authorize_url
      end

      # If the user approves your app, they will be presented with an
      # "authorization code". Have the user copy/paste that authorization
      # code into your app and then call this method to get an access token.
      #
      # Returns (access_token, user_id)
      # * +access_token+ is an access token string that can be passed to
      #   DropboxClient.
      # * +user_id+ is the Dropbox user ID of the user that just approved
      #   your app.
      def finish(code)
        get_token(code)
      end

    end

  end
end