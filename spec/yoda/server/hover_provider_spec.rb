require 'spec_helper'

RSpec.describe Yoda::Server::HoverProvider do
  LSP = ::LanguageServer::Protocol

  def file_uri(path)
    "file://#{File.expand_path(path, fixture_root)}"
  end

  let(:client_info) { described_class.new }
  after { client_info.project&.clean }

  let(:root_path) { fixture_root }
  let(:fixture_root) { File.expand_path('../../support/fixtures', __dir__) }
  let(:root_uri) { file_uri(root_path) }

  let(:client_info) { Yoda::Server::ClientInfo.new(root_uri) }
  let(:provider) { described_class.new(client_info) }

  describe '#request_hover' do
    before do
      client_info.setup
      client_info.file_store.load(uri)
    end
    subject { provider.request_hover(uri, position) }

    context 'request information in sample function' do
      let(:uri) { file_uri('lib/sample.rb') }
      let(:position) { { line: 7, character: 7 } }

      it 'returns completion for `self` variable' do
        expect(subject).to be_a(LSP::Interface::Hover)
        expect(subject.contents).to contain_exactly(/\AString/)
        expect(subject.range).to have_attributes(start: { line: 7, character: 6 }, end: { line: 7, character: 9 })
      end
    end

    context 'when the root namespace includes codes other than module definitions' do
      let(:uri) { file_uri('lib/sample3.rb') }
      let(:position) { { line: 13, character: 11} }

      it 'returns completion for `self` variable' do
        expect(subject).to be_a(LSP::Interface::Hover)
        expect(subject.contents).to contain_exactly('YodaFixture::Sample3.class')
        expect(subject.range).to have_attributes(start: { line: 13, character: 6 }, end: { line: 13, character: 13 })
      end
    end

  end
end
