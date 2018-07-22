require 'spec_helper'

RSpec.describe Yoda::Server::DefinitionProvider do
  LSP = ::LanguageServer::Protocol

  def file_uri(path)
    "file://#{File.expand_path(path, fixture_root)}"
  end

  let(:session) { described_class.new }
  after { session.project&.clean }

  let(:root_path) { fixture_root }
  let(:fixture_root) { File.expand_path('../../support/fixtures', __dir__) }
  let(:root_uri) { file_uri(root_path) }

  let(:session) { Yoda::Server::Session.new(root_uri) }
  let(:provider) { described_class.new(session) }

  describe '#provide' do
    before do
      session.setup
      session.file_store.load(uri)
    end
    subject { provider.provide(uri, position) }

    context 'request information on constant node in sample function' do
      let(:uri) { file_uri('lib/sample2.rb') }
      let(:position) { { line: 22, character: 10 } }

      it 'returns infomation of method1' do
        expect(subject).to contain_exactly(be_a(LSP::Interface::Location))
        expect(subject).to contain_exactly(
          have_attributes(
            uri: uri,
            range: have_attributes(start: { line: 0, character: 0 }, end: { line: 0, character: 0 })
          ),
        )
      end
    end

    context 'request information on send node in sample function' do
      let(:uri) { file_uri('lib/sample2.rb') }
      let(:position) { { line: 26, character: 10 } }

      it 'returns infomation of method1' do
        expect(subject).to contain_exactly(be_a(LSP::Interface::Location))
        expect(subject).to contain_exactly(
          have_attributes(
            uri: uri,
            range: have_attributes(start: { line: 10, character: 0 }, end: { line: 10, character: 0 })
          ),
        )
      end
    end
  end
end
