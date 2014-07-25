require 'net/http'
require 'cgi'
require 'openssl'

module Dropbox
  module API

    # This module processes all HTTP requests and responses for the SDK.
    #
    # For requests, do_http_request takes all the parts of a request,
    # assembles them, and sets SSL settings so that all requests to the
    # Dropbox servers are secure.
    module HTTP

      TRUSTED_CERT_FILE = File.join(File.dirname(File.dirname(__FILE__)),
          'trusted-certs.crt')
      HTTPS_PORT = 443

      # OpenSSL error codes for certificate validation.
      # See man page for 'verify' for the complete list.
      CERTIFICATE_SIGNATURE_FAILURE = 7
      CERTIFICATE_SUCCESS = 0

      # Converts a hash into a query string.
      #
      # Turns all keys/values into strings, escapes special characters,
      # and does not include any key/value pairs with a nil value.
      def self.make_query_string(params)
        new_params = {}
        params.each do |k, v|
          new_params[k.to_s] = v.to_s unless v.nil?
        end
        new_params.collect { |k, v|
          "#{ CGI.escape(k) }=#{ CGI.escape(v) }"
        }.join('&')
      end

      # Makes an http request out of the provided parts and
      # returns the response.
      #
      # Args:
      # * +method+: Indicates the request's HTTP method
      #   (Get, Post, or Put from the Net::HTTP module.)
      # * +host+: Host website (e.g 'www.dropbox.com')
      # * +path+: URL path (e.g. '/metadata')
      # * +client_identifier+: A string, typically of the form
      #   [app]/[version], indicating the identity of whoever is making
      #   the request. This will be part of the User-Agent HTTP header.
      # * +params+: A hash of the query parameters that will appear in the URL
      # * +headers+: A hash of HTTP headers, excluding User-Agent
      # * +body+: Data that will be the HTTP body. This can either be a string
      #   that will get copied, a file-like object that will be read into
      #   the body, or a hash that will be converted into query parameter
      #   format (e.g. POST requests).
      # * +cert_file+: A .crt file of trusted hosts. This parameter is only
      #   used for testing; it will always be TRUSTED_CERT_FILE in normal use.
      def self.do_http_request(method, host, path, client_identifier = '',
                               params = nil, headers = nil,
                               body = nil, cert_file = nil)
        cert_file ||= TRUSTED_CERT_FILE

        http, http_request = create_http_request(method, host, path,
                                                 client_identifier, params,
                                                 headers, body, cert_file)

        begin
          http.request(http_request)
        rescue OpenSSL::SSL::SSLError => e
          raise DropboxError.new("SSL error connecting to Dropbox. "\
              "There may be a problem with the set of certificates in"\
              " \"#{ cert_file }\". #{ e.message }")
        end
      end

      # Parses response. You probably shouldn't be calling this directly.
      #
      # This takes responses from the server and parses them.  It also checks
      # for errors and raises exceptions with the appropriate messages.
      #
      # Args:
      # * +response+: HTTP response object
      # * +raw+: If true, the response body is treated as raw data. Otherwise,
      #   it is treated as JSON. Defaults to false.
      def self.parse_response(response, raw = false)
        # Check for server errors
        if response.kind_of?(Net::HTTPServerError)
          fail DropboxError.new("Dropbox Server Error: #{ response } - "\
              "#{ response.body }", response)

        # Check for authentication errors
        elsif response.kind_of?(Net::HTTPUnauthorized)
          fail DropboxAuthError.new('User is not authenticated.', response)

        # Check for any other kind of error
        elsif !response.kind_of?(Net::HTTPSuccess)
          begin
            json = MultiJson.load(response.body)
          rescue
            fail DropboxError.new("Dropbox Server Error: body = "\
                "#{ response.body }", response)
          end

          if json['error']
            # user_error might be nil; it is internationalized if it exists
            fail DropboxError.new(json['error'], response, json['user_error'])
          else
            fail DropboxError.new(response.body, response)
          end
        end

        # Return the raw body for file content API endpoints
        if raw
          response.body

        # Assume it is JSON otherwise
        else
          begin
            MultiJson.load(response.body)
          rescue MultiJson::ParseError
            raise DropboxError.new("Unable to parse JSON response: "\
                "#{ response.body }", response)
          end
        end
      end

      # Creates and returns an http request object and an http object
      def self.create_http_request(method, host, path, client_identifier = '',
                                   params = nil, headers = nil,
                                   body = nil, cert_file = nil) #:nodoc:
        unless method < Net::HTTPRequest
          fail ArgumentError, "method must subclass Net::HTTPRequest; got "\
              "#{ method.inspect }"
        end

        http = Net::HTTP.new(host, HTTPS_PORT)
        set_ssl_settings(http, cert_file)

        params ||= {}
        path_and_params = "/#{ Dropbox::API::API_VERSION }#{ path }?"\
            "#{ make_query_string(params) }"
        http_request = method.new(path_and_params)
        http_request.initialize_http_header(headers)

        set_http_body(http_request, body)

        # Additional header.
        # We use this to better understand how developers are using our SDKs.
        http_request['User-Agent'] = "#{ client_identifier } "\
            "OfficialDropboxRubySDK/#{ Dropbox::API::SDK_VERSION }"

        return http, http_request
      end

      # Sets SSL settings so that all requests are configured correctly
      def self.set_ssl_settings(http, cert_file) # :nodoc:
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = cert_file.nil? ? TRUSTED_CERT_FILE : cert_file

        # SSL protocol and ciphersuite settings are supported starting with
        # Ruby 1.9
        if RUBY_VERSION >= '1.9'
          http.ssl_version = 'TLSv1'
          http.ciphers = 'ECDHE-RSA-AES256-GCM-SHA384:'\
                'ECDHE-RSA-AES256-SHA384:'\
                'ECDHE-RSA-AES256-SHA:'\
                'ECDHE-RSA-AES128-GCM-SHA256:'\
                'ECDHE-RSA-AES128-SHA256:'\
                'ECDHE-RSA-AES128-SHA:'\
                'ECDHE-RSA-RC4-SHA:'\
                'DHE-RSA-AES256-GCM-SHA384:'\
                'DHE-RSA-AES256-SHA256:'\
                'DHE-RSA-AES256-SHA:'\
                'DHE-RSA-AES128-GCM-SHA256:'\
                'DHE-RSA-AES128-SHA256:'\
                'DHE-RSA-AES128-SHA:'\
                'AES256-GCM-SHA384:'\
                'AES256-SHA256:'\
                'AES256-SHA:'\
                'AES128-GCM-SHA256:'\
                'AES128-SHA256:'\
                'AES128-SHA'
        end

        # Important security note!
        # Some Ruby versions (e.g. the one that ships with OS X) do not raise
        # an exception if certificate validation fails. We therefore have to
        # add a custom callback to ensure that invalid certs are not accepted.
        # Some specific error codes are let through, so we change the error
        # code to make sure that Ruby throws an exception if certificate
        # validation fails.
        #
        # You can comment out this code if your Ruby version is not vulnerable.
        http.verify_callback = proc do |preverify_ok, ssl_context|
          success = preverify_ok && ssl_context.error == CERTIFICATE_SUCCESS
          ssl_context.error = CERTIFICATE_SIGNATURE_FAILURE unless success
          success
        end
      end
      private_class_method :set_ssl_settings

      # Set the HTTP request body. It will be treated as raw data if the data
      # is file-like, a query string if it is a hash (e.g. in POST requests),
      # or a string otherwise.
      def self.set_http_body(http_request, body)
        return if body.nil?

        # Set query parameters in the body for POST requests
        if body.is_a?(Hash)
          http_request.body = make_query_string(body)

        # Or, set body contents for file uploads
        elsif body.respond_to?(:read)
          if body.respond_to?(:length)
            http_request['Content-Length'] = body.length.to_s
          elsif body.respond_to?(:stat) && body.stat.respond_to?(:size)
            http_request['Content-Length'] = body.stat.size.to_s
          else
            fail ArgumentError, "Don't know how to handle 'body' (responds to 'read' but not to 'length' or 'stat.size')."
          end
          http_request.body_stream = body

        # If all else fails, just make it a string
        else
          body = body.to_s
          http_request['Content-Length'] = body.length
          http_request.body = body
        end

        nil
      end
      private_class_method :set_http_body

    end
  end
end