require 'spec_helper'
require 'securerandom'

RSpec.describe Yoda::Server::RootHandler do
  TIMEOUT = 10

  include FileUriHelper
  let(:handler) { described_class.new(writer: Yoda::Server::ConcurrentWriter.new(writer), scheduler: scheduler) }
  let(:writer) { instance_double('Yoda::Server::ConcurrentWriter') }
  let(:thread_pool) { Concurrent.new_fast_executor(auto_terminate: true) }
  let(:scheduler) { Yoda::Server::Scheduler.new(thread_pool: thread_pool) }

  before { allow(writer).to receive(:write) }
  after { thread_pool.shutdown }

  shared_context 'after initialization' do
    before do
      handler.handle(
        id: SecureRandom.hex(10),
        method: :initialize,
        params: {
          root_uri: fixture_root_uri,
        },
      )
    end
  end

  shared_context 'after file read' do
    before { handler.session.file_store.load(uri) }
  end

  shared_context 'block thread execution' do
    let(:thread_pool) { Concurrent::SerializedExecutionDelegator.new(super()) }
    let(:event) { Concurrent::Event.new }

    before do
      Concurrent::Future.execute(executor: thread_pool) { event.wait }
    end
  end

  describe '#handle' do
    subject { handler.handle(id: id, method: method, params: params) }
    let(:id) { SecureRandom.hex(10) }

    describe 'with initialize method' do
      let(:method) { :initialize }
      let(:params) do
        {
          root_uri: fixture_root_uri,
        }
      end

      it 'sends capabilities' do
        expect(writer).to receive(:write).with(
          id: id,
          result: be_instance_of(LanguageServer::Protocol::Interface::InitializeResult),
        )

        subject
      end
    end

    describe 'with hover method' do
      include_context 'after initialization'
      include_context 'after file read'

      let(:method) { :'textDocument/hover' }
      let(:params) do
        {
          text_document: {
            uri: uri,
          },
          position: position,
        }
      end

      let(:uri) { file_uri('lib/root_handler_examples.rb') }
      let(:position) { { line: 2, character: 9 } }

      it 'returns future and send hover information' do
        expect(writer).to receive(:write).with(
          id: id,
          result: be_instance_of(LanguageServer::Protocol::Interface::Hover),
        )

        expect(subject).to be_a(Concurrent::Future)
        subject.wait!(TIMEOUT)
      end
    end

    describe 'with $/cancelRequest method' do
      include_context 'after initialization'
      include_context 'after file read'

      let(:method) { :'$/cancelRequest' }
      let(:params) do
        {
          id: another_request_id,
        }
      end

      context 'when another request is running' do
        include_context 'block thread execution'

        let(:another_request_id) { SecureRandom.hex(10) }
        let(:uri) { file_uri('lib/root_handler_examples.rb') }
        let(:position) { { line: 2, character: 9 } }

        let!(:another_request) do
          handler.handle(
            id: another_request_id,
            method: :'textDocument/hover',
            params: {
              text_document: {
                uri: uri,
              },
              position: position,
            },
          )
        end

        it 'cancels the request and sends cancel error' do
          expect(writer).not_to receive(:write).with(
            id: another_request_id,
            result: be_instance_of(LanguageServer::Protocol::Interface::Hover),
          )

          expect(writer).to receive(:write).with(
            id: another_request_id,
            error: have_attributes(
              code: LanguageServer::Protocol::Constant::ErrorCodes::REQUEST_CANCELLED,
              message: 'Request is canceled',
            )
          )

          subject
          event.set
          another_request.wait(TIMEOUT)
        end
      end
    end

    describe 'with wrong method name' do
      include_context 'after initialization'

      let(:method) { :'wrongMethodName' }
      let(:params) { Hash.new }

      it 'sends not implemented error' do
        expect(writer).to receive(:write).with(
          id: id,
          error: have_attributes(
            code: LanguageServer::Protocol::Constant::ErrorCodes::METHOD_NOT_FOUND,
            message: "Method (#{method}) is not implemented",
          )
        )

        subject
      end
    end
  end
end
