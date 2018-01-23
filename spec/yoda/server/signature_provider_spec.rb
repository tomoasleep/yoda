require 'spec_helper'

RSpec.describe Yoda::Server::SignatureProvider do
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

  describe '#provide' do
    before do
      client_info.setup
      client_info.file_store.load(uri)
    end
    subject { provider.provide(uri, position) }

    context 'request information in sample function' do
      let(:uri) { file_uri('lib/sample.rb') }
      let(:position) { { line: 15, character: 20 } }

      it 'returns infomation of method1' do
        expect(subject).to be_a(LSP::Interface::SignatureHelp)
        expect(subject.signatures).to include(
          have_attributes(
            label: include('method1(str: String)'),
            parameters: contain_exactly(
              have_attributes(label: 'str'),
            ),
          ),
        )
      end
    end
  end
end
