require 'spec_helper'

RSpec.describe Yoda::Server::SignatureProvider do
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

    context 'request information in sample function' do
      let(:uri) { file_uri('lib/sample.rb') }
      let(:position) { { line: 15, character: 20 } }

      it 'returns infomation of method1' do
        expect(subject).to be_a(LSP::Interface::SignatureHelp)
        expect(subject.signatures).to include(
          have_attributes(
            label: include('method1(String str)'),
            parameters: contain_exactly(
              have_attributes(label: 'str'),
            ),
          ),
        )
      end
    end
  end
end
