# Build a gem for RubyGems.org with user dropbox-api-team
# gem build gemspec.rb
# gem push dropbox-sdk-x.x.x.gem

Gem::Specification.new do |s|
  s.name = 'dropbox'

  s.version = '1.6.4' # TODO: put version info in its own file
  s.license = 'MIT'

  s.authors = ['Dropbox, Inc.']
  s.email = ['support-api@dropbox.com']

  s.add_runtime_dependency 'multi_json'

  s.add_development_dependency 'rspec'

  s.homepage = 'http://www.dropbox.com/developers/'
  s.summary = 'Dropbox REST API Client.'
  s.description = <<-EOF
    A library that provides a plain function-call interface to the
    Dropbox API web endpoints.
  EOF

  s.files = [ # TODO specify file list. use git ls-files?
    'CHANGELOG',
    'LICENSE',
    'README',
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
    'lib/dropbox/error.rb',
    'lib/dropbox/unsupported.rb',
    'lib/dropbox/objects/file.rb'
  ]
end
