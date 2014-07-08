require 'oauth2'
# require 'hashie' to be replaced because hashie doesn't allow for static code analysis
require 'multi_json'

module Dropbox
  module API
    
    API_SERVER = 'api.dropbox.com'
    API_CONTENT_SERVER = 'api-content.dropbox.com'
    WEB_SERVER = 'www.dropbox.com'

    API_VERSION = 1 # Version 2? :o
    SDK_VERSION = '1.6.4' # TODO put version info in its own file

    TRUSTED_CERT_FILE = File.join(File.dirname(__FILE__), 'trusted-certs.crt')

  end
end