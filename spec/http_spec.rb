require 'spec_helper'

def query_cmp(query1, query2)
  query1.split('&').sort == query2.split('&').sort
end

describe Dropbox::API::HTTP do
  describe '.clean_params' do
    it 'removes nil values' do
      before = { 'a' => nil, 'b' => 'not nil' }
      after = { 'b' => 'not nil' }
      expect(Dropbox::API::HTTP.clean_params(before)).to eq(after)
    end

    it 'converts everything to strings' do
      before = { :a => :b, 'c' => :d, :e => 'f' }
      after = { 'a' => 'b', 'c' => 'd', 'e' => 'f' }
      expect(Dropbox::API::HTTP.clean_params(before)).to eq(after)
    end
  end

  describe '.make_query_string' do
    it 'makes a valid query string' do
      params = { 'a' => 'b', :c => :d, 'e' => :f }
      query = 'a=b&c=d&e=f'
      expect(query_cmp(Dropbox::API::HTTP.make_query_string(params), query)).to be true
    end

    it 'escapes special characters' do
      key = '!@#$<>&'
      value = '/ %+"?'
      params = { key => value }
      query = "#{ CGI.escape(key) }=#{ CGI.escape(value) }"
      expect(Dropbox::API::HTTP.make_query_string(params)).to eq(query)
    end
  end

  describe '.do_http_request' do
    # This should mostly be tested by .create_http_request, minus actually making the request
    # TODO Mock?
  end

  describe '.create_http_request' do
    it 'does not accept non-Net::HTTPRequest methods' do
      expect { Dropbox::API::HTTP.create_http_request("String", 'host', 'path', nil, nil, nil) }.to raise_error(ArgumentError)
    end

    context 'returns http_request that' do
      it 'accepts Net::HTTP::Get' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, nil)
        expect(http_request).to be_instance_of(Net::HTTP::Get)
      end

      it 'accepts Net::HTTP::Post' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Post, 'host', '/path', nil, nil, nil)
        expect(http_request).to be_instance_of(Net::HTTP::Post)
      end

      it 'accepts Net::HTTP::Put' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Put, 'host', '/path', nil, nil, nil)
        expect(http_request).to be_instance_of(Net::HTTP::Put)
      end

      it 'sets path' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/my/test/path', nil, nil, nil)
        expect(http_request.path).to include('/my/test/path')
      end

      it 'adds API version' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/my/test/path', nil, nil, nil)
        expect(http_request.path.start_with?("/#{ Dropbox::API::API_VERSION }/my/test/path")).to be true
      end

      it 'sets params' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', { 'key1' => 'value1', 'key2' => 'value2' }, nil, nil)
        expect(query_cmp(http_request.path.split('?').last, 'key1=value1&key2=value2')).to be true
      end

      it 'sets headers' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, { 'key1' => 'value1', 'key2' => 'value2' }, nil)
        { 'key1' => 'value1', 'key2' => 'value2' }.each do |key, value|
          expect(http_request[key]).to eq(value)
        end
      end

      it 'always adds exactly one header (User-Agent)' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, nil)
        headers = {}
        http_request.each_header { |key, value| headers[key.downcase] = value }
        expect(headers).to eq({ 'user-agent' => "OfficialDropboxRubySDK/#{ Dropbox::API::SDK_VERSION }" })
      end

      it 'sets the body as a query given a hash' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, { key1: 'value1', key2: 'value2' })
        expect(query_cmp(http_request.body, 'key1=value1&key2=value2')).to be true
      end

      it 'sets raw body contents from file' do
        file = File.open(File.join(File.dirname(__FILE__), 'test_file.txt'), 'r')
        file_contents = file.readlines(nil)[0]
        file.rewind
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, file)
        headers = {}
        http_request.each_header { |key, value| headers[key.downcase] = value }
        expect(http_request.body_stream.readlines(nil)[0]).to eq(file_contents)
        expect(http_request.body).to be_nil
        expect(http_request['content-length']).to eq("#{ file_contents.length }")
      end

      it 'sets raw body contents from a string' do
        contents = "They don't think it be like it is, but it do."
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, contents)
        expect(http_request.body).to eq(contents)
        expect(http_request.body_stream).to be_nil
        expect(http_request['content-length']).to eq("#{ contents.length }")
      end
    end

    context 'returns http that' do
      it 'sets host' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, nil)
        expect(http.address).to eq('host')
      end

      it 'uses port 443' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, nil)
        expect(http.port).to eq(443)
      end

      it 'has correct SSL settings' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, nil)
        expect(http.use_ssl?).to be true
        expect(http.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
        expect(http.ca_file).to eq(Dropbox::API::HTTP::TRUSTED_CERT_FILE)

        if RUBY_VERSION >= '1.9'
          expect(http.ssl_version).to eq('TLSv1')
          expect(http.ciphers).to eq('ECDHE-RSA-AES256-GCM-SHA384:'\
                'ECDHE-RSA-AES256-SHA384:'\
                'ECDHE-RSA-AES256-SHA:'\
                'ECDHE-RSA-AES128-GCM-SHA256:'\
                'ECDHE-RSA-AES128-SHA256:'\
                'ECDHE-RSA-AES128-SHA:'\
                'ECDHE-RSA-RC4-SHA:'\
                'DHE-RSA-AES256-GCM-SHA384:'\
                'DHE-RSA-AES256-SHA256:'\
                'DHE-RSA-AES256-SHA:'\
                'DHE-RSA-AES128-GCM-SHA256:'\
                'DHE-RSA-AES128-SHA256:'\
                'DHE-RSA-AES128-SHA:'\
                'AES256-GCM-SHA384:'\
                'AES256-SHA256:'\
                'AES256-SHA:'\
                'AES128-GCM-SHA256:'\
                'AES128-SHA256:'\
                'AES128-SHA')
        end

      end

    end
  end

  describe '.parse_response' do
    class MyException1 < Net::HTTPServerError
      attr_reader :body
      def initialize(body)
        @body = body
      end

      def to_s
        'HTTPServerError stub'
      end
    end

    class MyException2 < Net::HTTPUnauthorized
      attr_reader :body
      def initialize(body)
        @body = body
      end

      def to_s
        'HTTPUnauthorized stub'
      end
    end

    class MyException3 < Net::HTTPClientError
      attr_reader :body
      def initialize(body)
        @body = body
      end

      def to_s
        'HTTPClientError stub'
      end
    end

    class SuccessResponse < Net::HTTPSuccess
      attr_reader :body
      def initialize(body)
        @body = body
      end

      def to_s
        'HTTPSuccess stub'
      end
    end

    it 'throws DropboxError on Net::HTTPServerError' do
      response = MyException1.new('Custom message')
      expected = Dropbox::API::DropboxError.new("Dropbox Server Error: #{ response } - #{ response.body }")
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::DropboxError, expected.to_s)
    end

    it 'throws DropboxAuthError on Net::HTTPUnauthorized' do
      response = MyException2.new('Custom message')
      expected = Dropbox::API::DropboxError.new('User is not authenticated.')
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::DropboxAuthError, expected.to_s)
    end

    it 'throws DropboxError if parsing error body fails' do
      response = MyException3.new('{Invalid json}')
      expected = Dropbox::API::DropboxError.new("Dropbox Server Error: body = #{ response.body }")
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::DropboxError, expected.to_s)
    end

    it 'throws DropboxError if json error exists' do
      response = MyException3.new('{"error": "Custom message", "user_error": "User error"}')
      expected = Dropbox::API::DropboxError.new('Custom message', nil, 'User error')
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::DropboxError, expected.to_s)
    end

    it 'throws DropboxError if json error doesn\'t exist' do
      response = MyException3.new('{"not_error": "Custom message"}')
      expected = Dropbox::API::DropboxError.new('{"not_error": "Custom message"}')
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::DropboxError, expected.to_s)
    end

    it 'returns body contents raw' do
      response = SuccessResponse.new('{"raw": "string"}')
      expect(Dropbox::API::HTTP.parse_response(response, true)).to eq('{"raw": "string"}')
    end

    it 'parses body contents as json' do
      response = SuccessResponse.new('{"raw": "string"}')
      expect(Dropbox::API::HTTP.parse_response(response)).to eq({ 'raw' => 'string' })
    end

    it 'throws DropboxError if parsing json fails' do
      response = SuccessResponse.new('{Invalid json}')
      expected = Dropbox::API::DropboxError.new("Unable to parse JSON response: {Invalid json}")
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::DropboxError, expected.to_s)
    end
  end

  # Not exactly a unit-test.
  describe 'certificate verification' do
    # This test might end up platform-dependent. Hopefully it won't.
    it 'rejects bad certificates from trusted-certs.crt' do

    end
  end

end