module Dropbox
  module API
    module Util

      def self.clean_params(params)
        # TODO there isn't a better way to do this?
        new_params = {}
        params.each do |k, v|
          new_params[k.to_s] = v.to_s unless v.nil?
        end
        new_params
      end

      def self.make_query_string(params)
        clean_params(params).collect { |k, v|
          "#{ CGI.escape(k) }=#{ CGI.escape(v) }"
        }.join('&')
      end

      # A string comparison function that is resistant to timing attacks.
      # If you're comparing a string you got from the outside world with a
      # string that is supposed to be a secret, use this function to check
      # equality.
      def self.safe_string_equals(a, b)
        a.length == b.length && a.chars.zip(b.chars).map { |ac, bc| ac == bc }.all?
      end

      def self.verify_ssl_certificate(preverify_ok, ssl_context)
        unless preverify_ok && ssl_context.error == 0
          err_msg = "SSL Verification failed -- Preverify: #{ preverify_ok }, Error: #{ ssl_context.error_string } (#{ ssl_context.error })"
          raise OpenSSL::SSL::SSLError.new(err_msg)
        end
        true
      end

    end
  end
end