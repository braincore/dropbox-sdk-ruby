# Build a gem for RubyGems.org with user dropbox-api-team
# gem build gemspec.rb
# gem push dropbox-sdk-x.x.x.gem

Gem::Specification.new do |s|
  s.name = 'dropbox'

  s.version = '2.0.0'
  s.license = 'MIT'

  s.authors = ['Dropbox, Inc.']
  s.email = ['support-api@dropbox.com']

  s.add_runtime_dependency 'oj'

  s.add_development_dependency 'rspec', '~> 2.2'
  s.add_development_dependency 'webmock'

  s.homepage = 'http://www.dropbox.com/developers/'
  s.summary = 'Dropbox REST API Client.'
  s.description = <<-EOF
    A library that provides a plain function-call interface to the
    Dropbox API web endpoints.
  EOF

  s.files = [
    'CHANGELOG',
    'LICENSE',
    'README.rdoc',
    'examples/cli_example.rb',
    'examples/dropbox_controller.rb',
    'examples/web_file_browser.rb',
    'examples/copy_between_accounts.rb',
    'examples/chunked_upload.rb',
    'examples/oauth1_upgrade.rb',
    'examples/search_cache.rb',
    'lib/dropbox.rb',
    'lib/trusted-certs.crt',
    'lib/dropbox/client.rb',
    'lib/dropbox/client/host_info.rb',
    'lib/dropbox/client/session.rb',
    'lib/dropbox/error.rb',
    'lib/dropbox/http.rb',
    'lib/dropbox/oauth2.rb',
    'lib/dropbox/oauth2/app_info.rb',
    'lib/dropbox/objects.rb',
    'lib/dropbox/unsupported.rb',
    'lib/dropbox/web_auth.rb',
    'lib/dropbox/web_auth_no_redirect.rb',
  ]
end
