require 'spec_helper'
require 'cgi'

describe Dropbox::API::HTTP do
  describe '.clean_params' do
    it 'should remove nil values' do
      before = { 'a' => nil, 'b' => 'not nil' }
      after = { 'b' => 'not nil' }
      expect(Dropbox::API::HTTP.clean_params(before)).to eq(after)
    end

    it 'should convert everything to strings' do
      before = { :a => :b, 'c' => :d, :e => 'f' }
      after = { 'a' => 'b', 'c' => 'd', 'e' => 'f' }
      expect(Dropbox::API::HTTP.clean_params(before)).to eq(after)
    end
  end

  describe '.make_query_string' do 
    def cmp(query1, query2)
      query1.split('&').sort == query2.split('&').sort
    end

    it 'should make a query string' do
      params = { 'a' => 'b', :c => :d, 'e' => :f }
      query = 'a=b&c=d&e=f'
      expect(cmp(query, Dropbox::API::HTTP.make_query_string(params))).to be true
    end

    it 'should escape special characters' do
      key = '!@#$<>&'
      value = '/ %+"?'
      params = { key => value }
      query = "#{ CGI.escape(key) }=#{ CGI.escape(value) }"
      expect(Dropbox::API::HTTP.make_query_string(params)).to eq(query)
    end
  end

  describe '.do_http_request' do

  end

  describe '.create_http_request' do

  end

  describe '.parse_response' do

  end

  describe 'SSL settings' do

  end

end