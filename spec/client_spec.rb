require 'spec_helper'

describe Dropbox::API::Client do

  before(:each) do
    @client = Dropbox::API::Client.new('token')
  end

  describe 'ChunkedUploader' do
    describe '.upload' do
      it 'wraps client.files method' do
        file = File.open(File.join(File.dirname(__FILE__), 'test_file.txt'))
        chunked_uploader = @client.get_chunked_uploader(file, file.stat.size)
        expect {
          chunked_uploader.upload(1)
        }.not_to raise_error
      end
    end

    describe '.finish' do
      it 'wraps client.files method' do
        file = File.open(File.join(File.dirname(__FILE__), 'test_file.txt'))
        chunked_uploader = @client.get_chunked_uploader(file.stat.size)
        expect {
          chunked_uploader.finish('/path.txt', WriteConflictPolicy.overwrite)
        }.not_to raise_error
      end
    end
  end
end