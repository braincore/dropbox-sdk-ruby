# file organization? this isn't really a class
# TODO mark all the classes in Tim Morgan's dropbox gem
# TODO check fail message
# -- how the hell do you deprecate stuff like Array?

module Dropbox

  OLD_VERSION_ERROR = "This object was used in an old version of the"\
      " 3rd-party 'dropbox' gem. The author agreed to give ownership of the"\
      " 'dropbox' gem to Dropbox, which is now the author/maintainer of this"\
      " gem. Please visit the official Dropbox developer site for"\
      " documentation of the current version."

  class Session
    def initialize(*args)
      fail Dropbox::OLD_VERSION_ERROR
    end
  end

  class Revision
    def initialize(*args)
      fail Dropbox::OLD_VERSION_ERROR
    end
  end

  class Event
    def initialize(*args)
      fail Dropbox::OLD_VERSION_ERROR
    end
  end

  class Entry
    def initialize(*args)
      fail Dropbox::OLD_VERSION_ERROR
    end
  end
end