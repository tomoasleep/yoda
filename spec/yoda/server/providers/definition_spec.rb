require 'spec_helper'

RSpec.describe Yoda::Server::Providers::Definition do
  include FileUriHelper

  let(:session) { Yoda::Server::Session.from_root_uri(fixture_root_uri) }
  let(:writer) { instance_double('Yoda::Server::ConcurrentWriter').as_null_object }
  let(:notifier) { Yoda::Server::Notifier.new(writer) }
  let(:provider) { described_class.new(session: session, notifier: notifier) }

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

    context 'request information on constant node in sample function' do
      let(:uri) { file_uri('lib/sample2.rb') }
      let(:position) { { line: 22, character: 10 } }

      it 'returns the location of Sample2 class' do
        expect(subject).to contain_exactly(be_a(LanguageServer::Protocol::Interface::Location))
        expect(subject).to contain_exactly(
          have_attributes(
            uri: uri,
            range: have_attributes(start: { line: 1, character: 0 }, end: { line: 1, character: 0 })
          ),
        )
      end
    end

    context 'request information on send node in sample function' do
      let(:uri) { file_uri('lib/sample2.rb') }
      let(:position) { { line: 26, character: 10 } }

      it 'returns the location of method2' do
        expect(subject).to contain_exactly(be_a(LanguageServer::Protocol::Interface::Location))
        expect(subject).to contain_exactly(
          have_attributes(
            uri: uri,
            range: have_attributes(start: { line: 11, character: 0 }, end: { line: 11, character: 0 })
          ),
        )
      end
    end

    context 'request information on type part of comment' do
      let(:uri) { file_uri('lib/sample2.rb') }
      let(:position) { { line: 15, character: 21 }}

      it 'returns location of Sample2 referred by the comment' do
        expect(subject).to contain_exactly(be_a(LanguageServer::Protocol::Interface::Location))
        expect(subject).to contain_exactly(
          have_attributes(
            uri: uri,
            range: have_attributes(start: { line: 1, character: 0 }, end: { line: 1, character: 0 })
          ),
        )
      end
    end
  end
end
