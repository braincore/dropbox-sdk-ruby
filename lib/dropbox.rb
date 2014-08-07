# require 'oauth2' uses Faraday, which does not support verify_callback for certificate validation
# require 'hashie' to be replaced because hashie doesn't allow for static code analysis
#require 'multi_json'
require 'oj'

module Dropbox
  module API

    API_SERVER = 'api.dropbox.com'
    API_CONTENT_SERVER = 'api-content.dropbox.com'
    WEB_SERVER = 'www.dropbox.com'

    API_VERSION = 2
    SDK_VERSION = '1.6.4' # TODO put version info in its own file? Version 2? :o

  end
end