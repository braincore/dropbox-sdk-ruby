module Dropbox
  module API

    # This is the usual error raised on any Dropbox related Errors
    class DropboxError < RuntimeError
      attr_accessor :http_response, :error, :user_error
      def initialize(error, http_response = nil, user_error = nil)
        @error = error
        @http_response = http_response
        @user_error = user_error
      end

      def to_s
        user_error ? "#{ user_error } (#{ error })" : error
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