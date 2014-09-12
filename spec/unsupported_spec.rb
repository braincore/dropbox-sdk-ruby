require 'spec_helper'

describe Dropbox::Session do
  describe 'class' do
    it 'should not be used' do
      expect { Dropbox::Session.new }.to raise_error(Dropbox::API::UnsupportedError)
    end
  end
end

describe Dropbox::Revision do
  describe 'class' do
    it 'should not be used' do
      expect { Dropbox::Revision.new }.to raise_error(Dropbox::API::UnsupportedError)
    end
  end
end

describe Dropbox::Event do
  describe 'class' do
    it 'should not be used' do
      expect { Dropbox::Event.new }.to raise_error(Dropbox::API::UnsupportedError)
    end
  end
end

describe Dropbox::Entry do
  describe 'class' do
    it 'should not be used' do
      expect { Dropbox::Entry.new }.to raise_error(Dropbox::API::UnsupportedError)
    end
  end
end
