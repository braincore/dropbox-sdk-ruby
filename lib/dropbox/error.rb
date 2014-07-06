module Dropbox
  module API

    # Thrown if the redirect URL was missing parameters or if the given parameters were not valid.
    #
    # The recommended action is to show an HTTP 400 error page.
    class BadRequestError < Exception; end

    # Thrown if all the parameters are correct, but there's no CSRF token in the session.  This
    # probably means that the session expired.
    #
    # The recommended action is to redirect the user's browser to try the approval process again.
    class BadStateError < Exception; end

    # Thrown if the given 'state' parameter doesn't contain the CSRF token from the user's session.
    # This is blocked to prevent CSRF attacks.
    #
    # The recommended action is to respond with an HTTP 403 error page.
    class CsrfError < Exception; end

    # The user chose not to approve your app.
    class NotApprovedError < Exception; end

    # Dropbox redirected to your redirect URI with some unexpected error identifier and error
    # message.
    class ProviderError < Exception; end

    # TODO above five errors obsolete due to oauth2 gem?

    # This is the usual error raised on any Dropbox related Errors
    class DropboxError < RuntimeError
      attr_accessor :http_response, :error, :user_error
      def initialize(error, http_response=nil, user_error=nil)
        @error = error
        @http_response = http_response
        @user_error = user_error
      end

      def to_s
        return "#{user_error} (#{error})" if user_error
        "#{error}"
      end
    end

    # This is the error raised on Authentication failures.  Usually this means
    # one of three things
    # * Your user failed to go to the authorize url and approve your application
    # * You set an invalid or expired token and secret on your Session
    # * Your user deauthorized the application after you stored a valid token and secret
    class DropboxAuthError < DropboxError
    end

    # This is raised when you call metadata with a hash and that hash matches
    # See documentation in metadata function
    class DropboxNotModified < DropboxError
    end

    # Thrown if a feature of an older version of the API is used.
    #
    # TODO recommended action?
    class UnsupportedError < Exception; end

  end
end