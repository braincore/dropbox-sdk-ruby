require 'spec_helper'

describe Dropbox::API::HTTP do

  describe '.clean_hash' do
    it 'converts keys and values to strings' do
      before = { :a => :b, 'c' => :d, :e => 'f' }
      after = { 'a' => 'b', 'c' => 'd', 'e' => 'f' }
      expect(Dropbox::API::HTTP.clean_hash(before)).to eq(after)
    end

    it 'removes nil values' do
      before = { 'a' => nil, 'b' => 'not_nil' }
      after = { 'b' => 'not_nil' }
      expect(Dropbox::API::HTTP.clean_hash(before)).to eq(after)
    end
  end

  describe '.make_query_string' do
    it 'converts to query format' do
      hash = { :a => :b, 'c' => :d, :e => 'f' }
      expect(make_hash(Dropbox::API::HTTP.make_query_string(hash))).to eq(make_hash('a=b&c=d&e=f'))
    end

    it 'escapes special characters' do
      key = '!@#$<>&'
      value = '/ %+"?'
      params = { key => value }
      query = "#{ CGI.escape(key) }=#{ CGI.escape(value) }"
      expect(Dropbox::API::HTTP.make_query_string(params)).to eq(query)
    end
  end

  describe '.create_http_request' do
    context 'returns http_request that' do
      it 'accepts Net::HTTP::Get' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path')
        expect(http_request).to be_instance_of(Net::HTTP::Get)
      end

      it 'accepts Net::HTTP::Post' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Post, 'host', '/path')
        expect(http_request).to be_instance_of(Net::HTTP::Post)
      end

      it 'accepts Net::HTTP::Put' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Put, 'host', '/path')
        expect(http_request).to be_instance_of(Net::HTTP::Put)
      end

      it 'sets path' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/my/test/path')
        expect(http_request.path).to include('/my/test/path')
      end

      it 'adds API version' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '')
        expect(http_request.path.start_with?("/#{ Dropbox::API::API_VERSION }")).to be true
      end

      it 'sets params' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', params: { 'key1' => 'value1', 'key2' => 'value2' })
        expect(make_hash(http_request.path.split('?').last)).to eq(make_hash('key1=value1&key2=value2'))
      end

      it 'sets headers' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', headers: { 'key1' => 'value1', 'key2' => 'value2' })
        { 'key1' => 'value1', 'key2' => 'value2' }.each do |key, value|
          expect(http_request[key]).to eq(value)
        end
      end

      it 'always adds User-Agent' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', client_identifier: 'client_test')
        headers = {}
        http_request.each_header { |key, value| headers[key.downcase] = value }
        expect(headers).to eq({ 'user-agent' => "client_test OfficialDropboxRubySDK/#{ Dropbox::API::SDK_VERSION }" })
      end

      it 'sets the body as json given a hash' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', body: { key1: 'value1', key2: 'value2' })
        expect(Oj.load(http_request.body)).to eq(make_hash('key1=value1&key2=value2'))
      end

      it 'sets raw body contents from file' do
        file = File.open(File.join(File.dirname(__FILE__), 'test_file.txt'), 'r')
        file_contents = file.readlines(nil)[0]
        file.rewind
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', body: file)
        headers = {}
        http_request.each_header { |key, value| headers[key.downcase] = value }
        expect(http_request.body_stream.readlines(nil)[0]).to eq(file_contents)
        expect(http_request.body).to be_nil
        expect(http_request['content-length']).to eq("#{ file_contents.length }")
        expect(http_request['content-type']).to eq('application/octet-stream')
      end

      it 'sets raw body contents from a string' do
        contents = "They don't think it be like it is, but it do."
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', body: contents)
        expect(http_request.body).to eq(contents)
        expect(http_request.body_stream).to be_nil
        expect(http_request['content-length']).to eq("#{ contents.length }")
      end
    end

    context 'returns http that' do
      it 'sets host' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path')
        expect(http.address).to eq('host')
      end

      it 'uses port 443' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path')
        expect(http.port).to eq(443)
      end

      it 'has correct SSL settings' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path')
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

      it 'sets custom certificate file' do
        http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', cert_file: 'filename')
        expect(http.ca_file).to eq('filename')
      end
    end
  end

  describe '.parse_response' do
    class HTTPResponseStub < Net::HTTPResponse
      attr_reader :code, :body, :header
      def initialize(code, body = nil, header = nil)
        @code = code.to_s
        @body = body
        @header = header
      end

      def [](key)
        if key == 'Dropbox-API-Result'
          header
        end
      end
    end

    # TODO Test translating HTTP response json to each EndpointError subclass

    it 'throws ServerError on HTTP 500' do
      response = HTTPResponseStub.new(500)
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::ServerError)
    end

    it 'throws TooManyRequestsError on HTTP 429' do
      response = HTTPResponseStub.new(429)
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::TooManyRequestsError)
    end

    it 'throws UnauthorizedError on HTTP 401' do
      response = HTTPResponseStub.new(401)
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::UnauthorizedError)
    end

    it 'throws BadRequestError on HTTP 400' do
      response = HTTPResponseStub.new(400)
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::BadRequestError)
    end

    it 'throws DropboxError if parsing json fails' do
      response = HTTPResponseStub.new(200, '{Invalid json}')
      expect {
        Dropbox::API::HTTP.parse_response(response)
      }.to raise_error(Dropbox::API::DropboxError, /JSON/)
    end

    it 'returns body contents and header for content endpoints' do
      response = HTTPResponseStub.new(200, '{"body": "body"}', '{"header": "header"}')
      body, header = Dropbox::API::HTTP.parse_response(response, true)
      expect(body).to eq('{"body": "body"}')
      expect(header).to eq({"header" => "header"})
    end

    it 'parses body contents as json for rpc endpoints' do
      response = HTTPResponseStub.new(200, '{"raw": "string"}')
      expect(Dropbox::API::HTTP.parse_response(response, false)).to eq({ 'raw' => 'string' })
    end
  end

  # Not exactly a unit-test. Requires actual internet connections.
  describe 'certificate verification' do
    before(:all) do
      WebMock.allow_net_connect!
    end

    after(:all) do
      WebMock.disable_net_connect!
    end

    it 'connects to Dropbox correctly' do
      expect {
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Get, Dropbox::API::WEB_SERVER, '/')
      }.not_to raise_error
    end

    # Make sure that this test passes on all platforms. It tests functionality that
    # used to only work for certains versions of Ruby (i.e. not OS X)
    it 'gets an SSL error if trusted-certs.crt doesn\'t have valid certs' do
      File.open('test_certs.crt', 'w').close
      expect {
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Get, Dropbox::API::WEB_SERVER, '/', cert_file: 'test_certs.crt')
      }.to raise_error(Dropbox::API::DropboxError, /SSL error.*test_certs\.crt/)
      File.delete('test_certs.crt')
    end

    it 'gets an SSL error on invalid hostname' do
      expect {
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Get, 'www.v.dropbox.com', '/')
      }.to raise_error(Dropbox::API::DropboxError, /SSL error.*www\.v\.dropbox\.com/)
    end

    it 'gets no error on certified non-Dropbox host' do
      expect {
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Get, 'www.digicert.com', '/')
      }.not_to raise_error
    end

    it 'gets an SSL error on uncertified host' do
      expect {
        Dropbox::API::HTTP.do_http_request(Net::HTTP::Get, 'www.twitter.com', '/')
      }.to raise_error(Dropbox::API::DropboxError, /SSL error.*trusted-certs\.crt/)
    end

  end

end