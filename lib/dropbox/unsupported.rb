# file organization? this isn't really a class

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