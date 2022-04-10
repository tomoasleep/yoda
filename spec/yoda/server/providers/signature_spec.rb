require 'spec_helper'

RSpec.describe Yoda::Server::Providers::Signature do
  include FileUriHelper

  let(:session) { Yoda::Server::Session.from_root_uri(fixture_root_uri) }
  let(:writer) { instance_double('Yoda::Server::ConcurrentWriter').as_null_object }
  let(:server_controller) { Yoda::Server::ServerController.new(writer: writer) }
  let(:provider) { described_class.new(session: session, server_controller: server_controller) }

  describe '#provide' do
    before do
      session.setup
      session.read_source(uri)
    end
    let(:params) do
      {
        text_document: {
          uri: uri,
        },
        position: position,
      }
    end
    subject { provider.provide(params) }

    context 'request information in sample function' do
      let(:uri) { file_uri('lib/sample.rb') }
      let(:position) { { line: 15, character: 20 } }

      it 'returns infomation of method1' do
        expect(subject).to be_a(LanguageServer::Protocol::Interface::SignatureHelp)
        expect(subject.signatures).to include(
          have_attributes(
            label: include('method1(::String str)'),
            parameters: contain_exactly(
              have_attributes(label: 'str'),
            ),
          ),
        )
      end
    end
  end
end
