module Dropbox
  module API
    module HTTP

      TRUSTED_CERT_FILE = File.join(File.dirname(__FILE__), 'trusted-certs.crt')

      # TODO: add all http stuff here?

      def self.do_request(uri, request) # :nodoc:

        http = Net::HTTP.new(uri.host, uri.port)

        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = TRUSTED_CERT_FILE

        if RUBY_VERSION >= '1.9'
          # SSL protocol and ciphersuite settings are supported starting with version 1.9
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
        # Some Ruby versions (e.g. the one that ships with OS X) do not raise an exception if certificate validation fails.
        # We therefore have to add a custom callback to ensure that invalid certs are not accepted
        # See https://www.braintreepayments.com/braintrust/sslsocket-verify_mode-doesnt-verify
        # You can comment out this code in case your Ruby version is not vulnerable
        #
        # TODO Comment about this. Error codes are in "man verify"
        http.verify_callback = proc do |preverify_ok, ssl_context|
          success = preverify_ok && ssl_context.error == 0
          ssl_context.error = 7 unless success
          success
        end

        #We use this to better understand how developers are using our SDKs.
        request['User-Agent'] =  "OfficialDropboxRubySDK/#{ Dropbox::API::SDK_VERSION }"

        begin
          http.request(request)
        rescue OpenSSL::SSL::SSLError => e
          raise DropboxError.new("SSL error connecting to Dropbox.  " +
                       "There may be a problem with the set of certificates in \"#{ TRUSTED_CERT_FILE }\".  #{e.message}")
        end
      end

    end
  end
end