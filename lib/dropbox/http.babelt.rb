# babelsdk(jinja2)

# This file is auto-generated from the babel template client.babelt.rb.
# Any changes here will silently disappear. And no, this isn't a
# reference to http://stackoverflow.com/a/740603/3862658. Changes will
# actually disappear.

{%- macro error_case(data_type, indent_spaces) %}
{%- filter indent(indent_spaces, indent_first=True) -%}
when '{{ data_type.name|string_slice(0, -5)|variable }}'
  fail {{ data_type.name|class }}.from_json(value, body['user_message'])
{%- endfilter -%}
{%- endmacro %}


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

      def self.clean_hash(hash)
        return hash unless hash.is_a?(Hash)
        new_hash = {}
        hash.each do |k, v|
          new_hash[k.to_s] = v.to_s unless v.nil?
        end
        new_hash
      end

      # Converts a hash into a query string.
      #
      # Turns all keys/values into strings, escapes special characters,
      # and does not include any key/value pairs with a nil value.
      def self.make_query_string(params)
        return unless params.is_a?(Hash)
        clean_hash(params).collect { |k, v|
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
      # * +path+: URL path with leading slash (e.g. '/metadata')
      #
      # Options:
      # * +client_identifier+: A string, typically of the form
      #   [app]/[version], indicating the identity of whoever is making the
      #   request. This will be part of the User-Agent HTTP header.
      # * +params+: A hash of the query parameters that will appear in the URL
      # * +headers+: A hash of HTTP headers, excluding User-Agent
      # * +body+: Data that will be the HTTP body. This can either be a string
      #   that will get copied, a file-like object that will be read into
      #   the body, or a hash that will be converted into JSON.
      # * +cert_file+: A .crt file of trusted hosts. This parameter is only
      #   used for testing; it will always be TRUSTED_CERT_FILE in normal use.
      # * +port+: Transport-layer port number. Defaults to 443 for HTTPS.
      def self.do_http_request(method, host, path, opts = {})
        cert_file = opts[:cert_file] || TRUSTED_CERT_FILE
        http, http_request = create_http_request(method, host, path, opts)

        begin
          http.request(http_request)
        rescue OpenSSL::SSL::SSLError => e
          raise DropboxError.new("SSL error connecting to Dropbox. "\
              "There may be a problem with the set of certificates in"\
              " \"#{ cert_file }\". #{ e.message }")
        end
      end

      def self.parse_content_response(response)
        parse_response(response, true)
      end

      def self.parse_rpc_response(response)
        parse_response(response, false)
      end

      # This takes responses from the server and parses them.  It also checks
      # for errors and raises exceptions with the appropriate messages. You
      # shouldn't be calling this directly.
      def self.parse_response(response, is_content_endpoint=false)

        # TODO Figure out the error format for each generic error and
        # initialize each one accordingly. Also, figure out how the
        # endpoint-specific part should be generated (or not
        # generated).

        case response.code.to_i
        when 500
          fail ServerError.new(response.body)
        when 429
          fail TooManyRequestsError.new(response.body)
        when 401
          fail UnauthorizedError.new(response.body)
        when 400
          fail BadRequestError.new(response.body)
        when 409
          body = Oj.load(response.body)
          key, value = get_key_value(body['reason'])
          #case key
          {% for namespace in api.namespaces.values() %}
            {% for data_type in namespace.data_types %}
              {% if data_type.name.endswith('Error') and data_type.composite_type == 'struct' %}
                {{- error_case(data_type, 10) }}
              {% endif %}
            {% endfor %}
          {% endfor %}
          #end
        when 200
          if is_content_endpoint
            json = Oj.load(response['Dropbox-API-Result'])
            return response.body, json
          else
            Oj.load(response.body)
          end
        else
          fail DropboxError.new("Unknown error with HTTP status "\
              "#{ response.code }: #{ response.body }")
        end
      rescue Oj::ParseError
        fail DropboxError.new("Unable to parse JSON response: "\
            "#{ response.body }")
      end

      # Creates and returns an http request object and an http object
      def self.create_http_request(method, host, path, opts = {}) #:nodoc:
        client_identifier = opts[:client_identifier] || ''
        params = clean_hash(opts[:params])
        headers = clean_hash(opts[:headers])
        body = clean_hash(opts[:body])
        cert_file = opts[:cert_file] || TRUSTED_CERT_FILE
        port = opts[:port] || HTTPS_PORT

        # Check port. If connecting to Dropbox servers, must be using SSL.
        http = Net::HTTP.new(host, port)
        if port == HTTPS_PORT
          set_ssl_settings(http, cert_file)
        elsif host.include?('dropbox.com')
          fail ArgumentError, "Must use SSL to connect to Dropbox servers."
        end

        # Temporary fix for OAuth for testing until v2 stuff is finished.
        # Unit tests require always using API_VERSION, but servers only
        # will respond to /1/
        # TODO get rid of the first oauth special case and just use the
        # second general case
        #if path['oauth']
        #  path_and_params = "/1#{ path }?#{ make_query_string(params) }"
        #else
          path_and_params = "/#{ API_VERSION }#{ path }?"\
              "#{ make_query_string(params) }"
        #end

        http_request = method.new(path_and_params)
        http_request.initialize_http_header(headers)

        set_http_body(http_request, body)

        # Additional header.
        # We use this to better understand how developers are using our SDKs.
        http_request['User-Agent'] = "#{ client_identifier } "\
            "OfficialDropboxRubySDK/#{ SDK_VERSION }"

        return http, http_request
      end

      # Sets SSL settings so that all requests are configured correctly
      def self.set_ssl_settings(http, cert_file) # :nodoc:
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = cert_file

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
      # is file-like or formatted as JSON if it is a hash.
      def self.set_http_body(http_request, body) # :nodoc:
        return unless body

        if body.is_a?(Hash)
          # Set query parameters in the body for POST requests
          http_request.body = Oj.dump(body, mode: :compat)
          http_request['Content-Type'] = 'application/json'

        elsif body.respond_to?(:read)
          # Or, set body contents for file uploads
          if body.respond_to?(:length)
            http_request['Content-Length'] = body.length.to_s
          elsif body.respond_to?(:stat) && body.stat.respond_to?(:size)
            http_request['Content-Length'] = body.stat.size.to_s
          else
            fail ArgumentError, "Don't know how to handle 'body' (responds "\
                "to 'read' but not to 'length' or 'stat.size')."
          end
          http_request['Content-Type'] = 'application/octet-stream'
          http_request.body_stream = body

        else
          # If all else fails, just make it a string
          body = body.to_s
          http_request['Content-Length'] = body.length
          http_request.body = body
        end
      end
      private_class_method :set_http_body

    end
  end
end
