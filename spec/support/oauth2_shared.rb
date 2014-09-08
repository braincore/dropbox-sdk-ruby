require 'spec_helper'

shared_examples 'OAuth2' do

  # Make private methods public for testing
  before(:each) do
    auth.class.send(:public, *auth.class.private_instance_methods)
  end

  shared_examples '#oauth2_init' do
    it 'defaults locale to nil' do
      app_info = Dropbox::API::AppInfo.new('app_key', 'app_secret')
      auth.oauth2_init(app_info)
      expect(auth.locale).to be_nil
    end
  end

  shared_examples '#get_authorize_url' do
    it 'adds passed-in query params' do
      expect(auth.get_authorize_url(test_key: 'test_value').split('?').last).to include('test_key=test_value')
    end

    it 'contains correct params' do
      expected = {
        'client_id' => 'app_key',
        'response_type' => 'code'
      }
      actual = make_hash(auth.get_authorize_url.split('?').last)
      expect(actual).to eq(expected)
    end

    it 'returns correct URL' do
      expect(auth.get_authorize_url.split('?').first).to eq("https://#{ Dropbox::API::WEB_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/authorize")
    end
  end

  shared_examples '#get_token' do
    it 'returns access token and uid from response body' do
      stub_body = Oj.dump({
        'token_type' => 'bearer',
        'access_token' => 'returned_access_token',
        'uid' => 'returned_uid'
      })
      stub_request(:any, "https://app_key:app_secret@#{ Dropbox::API::API_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/token")
          .with(query: {code: 'sample_code', grant_type: 'authorization_code'})
          .to_return(status: 200, body: stub_body)
      returned_access_token, returned_uid = auth.get_token('sample_code')
      expect(returned_access_token).to eq('returned_access_token')
      expect(returned_uid).to eq('returned_uid')
    end

    it 'requests correct URL with params' do
      stub_body = Oj.dump({
        'token_type' => 'bearer',
        'access_token' => 'returned_access_token',
        'uid' => 'returned_uid'
      })
      stub_request(:post, "https://app_key:app_secret@#{ Dropbox::API::API_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/token")
          .with(query: { 'grant_type' => 'authorization_code', 'code' => 'sample_code', 'other_param' => 'other' })
          .to_return(status: 200, body: stub_body)
      expect {
        auth.get_token('sample_code', 'other_param' => 'other')
      }.not_to raise_error
    end

    it 'throws DropboxError if token_type is not bearer' do
      stub_body = Oj.dump({
        'token_type' => 'not_bearer',
        'access_token' => 'returned_access_token',
        'uid' => 'returned_uid'
      })
      stub_request(:any, "https://app_key:app_secret@#{ Dropbox::API::API_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/token")
          .with(query: {code: 'sample_code', grant_type: 'authorization_code'})
          .to_return(status: 200, body: stub_body)
      expect {
        auth.get_token('sample_code')
      }.to raise_error(Dropbox::API::DropboxError, /token_type/)
    end

    it 'throws DropboxError if body does not have token_type' do
      stub_body = Oj.dump({
        'access_token' => 'returned_access_token',
        'uid' => 'returned_uid'
      })
      stub_request(:any, "https://app_key:app_secret@#{ Dropbox::API::API_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/token")
          .with(query: {code: 'sample_code', grant_type: 'authorization_code'})
          .to_return(status: 200, body: stub_body)
      expect {
        auth.get_token('sample_code')
      }.to raise_error(Dropbox::API::DropboxError, /token_type/)
    end

    it 'throws DropboxError if token_type is not a String' do
      stub_body = Oj.dump({
        'token_type' => 0,
        'access_token' => 'returned_access_token',
        'uid' => 'returned_uid'
      })
      stub_request(:any, "https://app_key:app_secret@#{ Dropbox::API::API_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/token")
          .with(query: {code: 'sample_code', grant_type: 'authorization_code'})
          .to_return(status: 200, body: stub_body)
      expect {
        auth.get_token('sample_code')
      }.to raise_error(Dropbox::API::DropboxError, /token_type/)
    end

    it 'throws DropboxError if body does not have access_token' do
      stub_body = Oj.dump({
        'token_type' => 'bearer',
        'uid' => 'returned_uid'
      })
      stub_request(:any, "https://app_key:app_secret@#{ Dropbox::API::API_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/token")
          .with(query: {code: 'sample_code', grant_type: 'authorization_code'})
          .to_return(status: 200, body: stub_body)
      expect {
        auth.get_token('sample_code')
      }.to raise_error(Dropbox::API::DropboxError, /access_token/)
    end

    it 'throws DropboxError if access_token is not a String' do
      stub_body = Oj.dump({
        'token_type' => 'bearer',
        'access_token' => 0,
        'uid' => 'returned_uid'
      })
      stub_request(:any, "https://app_key:app_secret@#{ Dropbox::API::API_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/token")
          .with(query: {code: 'sample_code', grant_type: 'authorization_code'})
          .to_return(status: 200, body: stub_body)
      expect {
        auth.get_token('sample_code')
      }.to raise_error(Dropbox::API::DropboxError, /access_token/)
    end

    it 'throws DropboxError if body does not have uid' do
      stub_body = Oj.dump({
        'token_type' => 'bearer',
        'access_token' => 'returned_access_token'
      })
      stub_request(:any, "https://app_key:app_secret@#{ Dropbox::API::API_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/token")
          .with(query: {code: 'sample_code', grant_type: 'authorization_code'})
          .to_return(status: 200, body: stub_body)
      expect {
        auth.get_token('sample_code')
      }.to raise_error(Dropbox::API::DropboxError, /uid/)
    end

    it 'throws DropboxError if uid is not a String' do
      stub_body = Oj.dump({
        'token_type' => 'bearer',
        'access_token' => 'returned_access_token',
        'uid' => 0
      })
      stub_request(:any, "https://app_key:app_secret@#{ Dropbox::API::API_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/token")
          .with(query: {code: 'sample_code', grant_type: 'authorization_code'})
          .to_return(status: 200, body: stub_body)
      expect {
        auth.get_token('sample_code')
      }.to raise_error(Dropbox::API::DropboxError, /uid/)
    end

  end

end