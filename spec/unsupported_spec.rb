require 'spec_helper'

describe Dropbox::API::DropboxSessionBase do
  describe 'class' do
    it 'should not be used' do
      expect { Dropbox::API::DropboxSessionBase.new }.to raise_error(Dropbox::API::UnsupportedError)
    end
  end
end

describe Dropbox::API::DropboxSession do
  describe 'class' do
    it 'should not be used' do
      expect { Dropbox::API::DropboxSession.new }.to raise_error(Dropbox::API::UnsupportedError)
    end
  end
end

describe Dropbox::API::DropboxOAuth2Session do
  describe 'class' do
    it 'should not be used' do
      expect { Dropbox::API::DropboxOAuth2Session.new }.to raise_error(Dropbox::API::UnsupportedError)
    end
  end
end

describe Dropbox::API::DropboxOAuth2FlowBase do
  describe 'class' do
    it 'should not be used' do
      expect { Dropbox::API::DropboxOAuth2FlowBase.new }.to raise_error(Dropbox::API::UnsupportedError)
    end
  end
end

describe Dropbox::API::DropboxOAuth2Flow do
  describe 'class' do
    it 'should not be used' do
      expect { Dropbox::API::DropboxOAuth2Flow.new }.to raise_error(Dropbox::API::UnsupportedError)
    end
  end
end

describe Dropbox::API::DropboxOAuth2FlowNoRedirect do
  describe 'class' do
    it 'should not be used' do
      expect { Dropbox::API::DropboxOAuth2FlowNoRedirect.new }.to raise_error(Dropbox::API::UnsupportedError)
    end
  end
end