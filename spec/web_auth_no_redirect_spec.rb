require 'spec_helper'

describe Dropbox::API::WebAuth do

  describe '#initialize' do
    it_behaves_like 'OAuth2' do
      it_behaves_like '#oauth2_init' do
        let(:auth) { Dropbox::API::WebAuthNoRedirect.new('app_key', 'app_secret') }
      end
    end
  end

  describe '#start' do
    it_behaves_like 'OAuth2' do
      it_behaves_like '#get_authorize_url' do
        let(:auth) { Dropbox::API::WebAuthNoRedirect.new('app_key', 'app_secret') }
      end
    end
  end

  describe '#finish' do
    it_behaves_like 'OAuth2' do
      it_behaves_like '#get_token' do
        let(:auth) { Dropbox::API::WebAuthNoRedirect.new('app_key', 'app_secret') }
      end
    end
  end
end