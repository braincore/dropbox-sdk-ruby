cd ~/src/dropbox-sdk-ruby
rm -rf doc
rdoc --exclude ".*babelt.*|examples/.*|rspec/*"
