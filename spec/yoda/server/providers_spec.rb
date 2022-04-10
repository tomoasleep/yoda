require 'spec_helper'

RSpec.describe Yoda::Server::Providers do
  include FileUriHelper
  let(:providers) { described_class }

  describe '.build_provider' do
    subject { providers.build_provider(method: method, session: session) }

    let(:session) { Yoda::Server::Session.from_root_uri(fixture_root_uri, server_controller: server_controller) }
    let(:writer) { instance_double('Yoda::Server::ConcurrentWriter').as_null_object }
    let(:server_controller) { Yoda::Server::ServerController.new(writer: writer) }

    context 'for textDocument/completion method' do
      let(:method) { :'textDocument/completion' }
      it { is_expected.to be_a(Yoda::Server::Providers::Completion) }
    end

    context 'for textDocument/hover method' do
      let(:method) { :'textDocument/hover' }
      it { is_expected.to be_a(Yoda::Server::Providers::Hover) }
    end

    context 'for textDocument/signatureHelp method' do
      let(:method) { :'textDocument/signatureHelp' }
      it { is_expected.to be_a(Yoda::Server::Providers::Signature) }
    end

    context 'for textDocument/definition method' do
      let(:method) { :'textDocument/definition' }
      it { is_expected.to be_a(Yoda::Server::Providers::Definition) }
    end

    context 'for textDocument/didOpen method' do
      let(:method) { :'textDocument/didOpen' }
      it { is_expected.to be_a(Yoda::Server::Providers::TextDocumentDidOpen) }
    end

    context 'for textDocument/didSave method' do
      let(:method) { :'textDocument/didSave' }
      it { is_expected.to be_a(Yoda::Server::Providers::TextDocumentDidSave) }
    end

    context 'for textDocument/didChange method' do
      let(:method) { :'textDocument/didChange' }
      it { is_expected.to be_a(Yoda::Server::Providers::TextDocumentDidChange) }
    end
  end
end
