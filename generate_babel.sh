cd ../babelsdk

# cp example/template/dropbox-ruby-sdk/*.babelt.rb ../dropbox-sdk-ruby/lib/dropbox/

python -m babelsdk.cli example/api/v2_files.babel example/api/v2_users.babel ../dropbox-sdk-ruby/lib/dropbox

cd ../dropbox-sdk-ruby

./generate_docs.sh
