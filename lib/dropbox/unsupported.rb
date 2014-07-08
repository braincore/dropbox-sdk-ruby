# file organization? this isn't really a class
# TODO is all this actually obsolete from oauth2 gem?
# TODO mark all the classes in Tim Morgan's dropbox gem
# -- how the hell do you deprecate stuff like Array?

require 'dropbox/error'

module Dropbox
  module API
    def self.deprecated
      fail UnsupportedError, 'TODO: Message about old gem'
    end
    
    class DropboxSessionBase
      def initialize
        Dropbox::API::deprecated
      end
    end

    class DropboxSession
      def initialize
        Dropbox::API::deprecated
      end
    end

    class DropboxOAuth2Session
      def initialize
        Dropbox::API::deprecated
      end
    end

    class DropboxOAuth2FlowBase
      def initialize
        Dropbox::API::deprecated
      end
    end

    class DropboxOAuth2Flow
      def initialize
        Dropbox::API::deprecated
      end
    end

    class DropboxOAuth2FlowNoRedirect
      def initialize
        Dropbox::API::deprecated
      end
    end
  end
end