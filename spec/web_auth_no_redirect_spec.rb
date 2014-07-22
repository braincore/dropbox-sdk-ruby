require 'spec_helper'

describe Dropbox::API::WebAuth do

  before(:each) do
    app_info = Dropbox::API::AppInfo.new('app_key', 'app_secret')
    @auth = Dropbox::API::WebAuthNoRedirect.new(app_info, 'client_test')
  end

  it_behaves_like 'OAuth2' do
    describe '#initialize' do
      it_behaves_like '#oauth2_init' do
        let(:auth) { @auth }
      end
    end

    describe '#start' do
      it_behaves_like '#get_authorize_url' do
        let(:auth) { @auth }
      end
    end

    describe '#finish' do
      it_behaves_like '#get_token' do
        let(:auth) { @auth }
      end
    end
  end
end