# file organization? this isn't really a class
# TODO mark all the classes in Tim Morgan's dropbox gem
# -- how the hell do you deprecate stuff like Array?

require 'dropbox/error'

module Dropbox
  module API
    def self.deprecated
      fail UnsupportedError, 'TODO: Message about old gem'
    end
    
    #class DropboxSessionBase
    #  def initialize
    #    Dropbox::API::deprecated
    #  end
    #end
  end
end