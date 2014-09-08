# Objects in this module are those that were in the previous version of the
# 'dropbox' gem. The original author agreed to give ownership of the gem to
# Dropbox, which is now the author/maintainer of this gem.

module Dropbox
  class Session
    def initialize(*args)
      fail Dropbox::API::UnsupportedError
    end
  end

  class Revision
    def initialize(*args)
      fail Dropbox::API::UnsupportedError
    end
  end

  class Event
    def initialize(*args)
      fail Dropbox::API::UnsupportedError
    end
  end

  class Entry
    def initialize(*args)
      fail Dropbox::API::UnsupportedError
    end
  end
end