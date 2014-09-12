module Dropbox
  module API

    # This is the error raised on any Dropbox server-related errors
    class DropboxError < RuntimeError; end

    # This is the superlcass for errors raised on an API call, but where the
    # error is not specific to the API endpoint.
    class GenericAPIError < DropboxError
      attr_accessor :http_status
      def initialize(message, http_status)
        super(message)
        @http_status = http_status
      end
    end

    # The request was malformed.
    #
    # TODO add additional user_message from response body
    class BadRequestError < GenericAPIError
      def initialize(message)
        super(message, '400')
      end
    end

    # This is the error raised on authentication failures.  Usually this means
    # one of three things:
    # * Your user failed to go to the authorize url and approve your application
    # * You set an invalid or expired token on your Session
    # * Your user deauthorized the application after you stored a valid token
    #
    # TODO add machine-readable body with additional info
    class UnauthorizedError < GenericAPIError
      def initialize(message)
        super(message, '401')
      end
    end

    # You are making too many requests to the Dropbox API. Look at the HTTP
    # "Retry-After" header to find out when you can start making requests
    # again.
    class TooManyRequestsError < GenericAPIError
      def initialize(message)
        super(message, '429')
      end
    end

    # The server could not complete the request because of an error on
    # Dropbox's part.
    class ServerError < GenericAPIError
      def initialize(message)
        super(message, '500')
      end
    end

    # This is the superclass for errors raised for an API endpoint-specific
    # issue. It means the request was well-formed and valid, but the endpoint
    # itself was not able to complete the request.
    #
    # user_message is a localized user-friendly string describing the error.
    # error_data contains more specific machine-readable information.
    #
    # Specific error types are described in objects.rb.
    class EndpointError < DropboxError
      attr_accessor :user_message, :error_data
      def initialize(user_message, error_data = nil)
        @error_data = error_data
        @user_message  = user_message
      end
    end

    # Thrown if objects from the previous version of the 'dropbox' gem are
    # detected.
    class UnsupportedError < Exception

      ERROR_MESSAGE = "This object was used in an old version of the"\
          " 3rd-party 'dropbox' gem. The author agreed to give ownership of the"\
          " 'dropbox' gem to Dropbox, which is now the author/maintainer of "\
          " this gem. Please visit the official Dropbox developer site for"\
          " documentation of the current version."

      def initialize
        super(ERROR_MESSAGE)
      end
    end

  end
end