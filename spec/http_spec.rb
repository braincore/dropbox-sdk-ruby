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

    it 'sets host' do
      http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, nil)
      expect(http.address).to eq('host')
    end

    it 'uses port 443' do
      http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, nil)
      expect(http.port).to eq(443)
    end

    it 'sets path' do
      http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/my/test/path', nil, nil, nil)
      expect(http_request.path).to include('/my/test/path')
    end

    it 'adds API version' do
      http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/my/test/path', nil, nil, nil)
      expect(http_request.path.start_with?("/#{ Dropbox::API::API_VERSION }")).to be true
    end

    it 'sets params' do
      http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', { 'key1' => 'value1', 'key2' => 'value2' }, nil, nil)
      expect(query_cmp(http_request.path.split('?').last, 'key1=value1&key2=value2')).to be true
    end

    it 'sets headers' do
      http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, { 'key1' => 'value1', 'key2' => 'value2' }, nil)
      headers = { 'key1' => 'value1', 'key2' => 'value2' }
      http_request.each_header { |key, value| headers.delete(key) }
      expect(headers).to be_empty
    end

    it 'always adds exactly one header (User-Agent)' do
      http, http_request = Dropbox::API::HTTP.create_http_request(Net::HTTP::Get, 'host', '/path', nil, nil, nil)
      headers = {}
      http_request.each_header { |key, value| headers[key.downcase] = value }
      expect(headers).to eq({ 'user-agent' => "OfficialDropboxRubySDK/#{ Dropbox::API::SDK_VERSION }" })
    end

  end

  describe '.parse_response' do

  end

  describe 'SSL settings' do
    #it 'should use HTTPS' do

    #end
  end

end