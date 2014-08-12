require 'webmock/rspec'

require_relative '../lib/dropbox'
require_relative '../lib/dropbox/client'
require_relative '../lib/dropbox/error'
require_relative '../lib/dropbox/unsupported'
require_relative '../lib/dropbox/http'
require_relative '../lib/dropbox/oauth2'
require_relative '../lib/dropbox/web_auth'
require_relative '../lib/dropbox/web_auth_no_redirect'
require_relative '../lib/dropbox/oauth2/app_info'
require_relative '../lib/dropbox/client/host_info'
require_relative '../lib/dropbox/objects'
require_relative '../lib/dropbox/fileops'

def make_hash(query)
  result = {}
  query.split('&').each do |pair|
    key, value = pair.split('=', 2)
    result[key] = value
  end
  result
end