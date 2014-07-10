module Dropbox
  module API
    module Util

      # A string comparison function that is resistant to timing attacks.
      # If you're comparing a string you got from the outside world with a
      # string that is supposed to be a secret, use this function to check
      # equality.
      def self.safe_string_equals(a, b)
        a.length == b.length && a.chars.zip(b.chars).map { |ac, bc| ac == bc }.all?
      end

    end
  end
end