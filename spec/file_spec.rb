require 'spec_helper'

describe Dropbox::API::File do
  it 'subclasses FileInfo' do
    expect(File.superclass).to eq(Dropbox::API::FileInfo)
  end

  it_behaves_like 'Fileops' do
    let(:file) { File.new }
  end
end
