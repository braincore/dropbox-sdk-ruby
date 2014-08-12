module Dropbox
  module API

    class GenericError < RuntimeError
      attr_accessor :error_data, :status

      def initialize(error_data, status)
        @error_data = error_data
        @status = status
      end
    end

    class BadRequestError < GenericError
      def initialize(error_data)
        super(error_data, 400)
      end
    end

    class UnauthorizedError < GenericError
      def initialize(error_data)
        super(error_data, 401)
      end
    end

    class TooManyRequestsError < GenericError
      def initialize(error_data)
        super(error_data, 429)
      end
    end

    class ServerError < GenericError
      def initialize(error_data)
        super(error_data, 500)
      end
    end

    # TODO finish once error formatting is determined
    class APIError < RuntimeError
      STATUS = 409

      attr_accessor :error_data, :status

      def initialize(error_data)
        @status = STATUS
        @error = error_data[:error]
        @user_message = error_data[:user_message]
      end
    end

    ###################################

    # This is the usual error raised on any Dropbox related Errors
    # TODO http_response is passed in but not used
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