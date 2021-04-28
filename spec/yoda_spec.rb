require 'spec_helper'
require 'support/helpers/server_helper'

RSpec.describe Yoda do
  let(:executable) { File.expand_path("../exe/yoda", __dir__) }
  let(:fixture_path) { File.expand_path("./support/fixtures", __dir__) }
  
  describe "server" do
    include ServerHelper

    let(:command) { "#{executable} server --log-level=trace" }

    it "can launch" do
      messages, error, status = capture_server(command: command, fixture_path: fixture_path) do |requests|
        requests << lsp_request(
          id: "test",
          method: :initialize,
          params: {
            process_id: nil,
            root_uri: fixture_path,
            capabilities: lsp(:client_capabilities),
          }
        )
      end

      puts error
      expect(messages[0]).not_to have_key(:error)
    end

    it "can open file" do
      messages, error, status = capture_server(command: command, fixture_path: fixture_path) do |requests|
        requests << lsp_request(
          id: "test",
          method: :initialize,
          params: {
            process_id: nil,
            root_uri: nil,
            capabilities: lsp(:client_capabilities),
          }
        )

        requests << lsp_request(
          id: "test-new",
          method: :initialized,
          params: {}
        )

        sample_path = File.expand_path('./lib/sample.rb', fixture_path)

        requests << lsp_request(
          id: "test-new",
          method: :'textDocument/didOpen',
          kind: :'did_open_text_document',
          params: {
            text_document: lsp(
              :text_document_item,
              uri: "file://#{sample_path}",
              language_id: "ruby",
              version: 1,
              text: File.read(sample_path),
            ),
          }
        )
      end

      puts error
      messages.each do |message|
        expect(message).not_to have_key(:error)
      end
    end

    it "can complete" do
      messages, error, status = capture_server(command: command, fixture_path: fixture_path) do |requests|
        requests << lsp_request(
          id: "test",
          method: :initialize,
          params: {
            process_id: nil,
            root_uri: nil,
            capabilities: lsp(:client_capabilities),
          }
        )

        requests << lsp_request(
          id: "test-new",
          method: :initialized,
          params: {}
        )

        sample_path = File.expand_path('./lib/object.rb', fixture_path)

        requests << lsp_request(
          id: "test-new",
          method: :'textDocument/didOpen',
          kind: :'did_open_text_document',
          params: {
            text_document: lsp(
              :text_document_item,
              uri: "file://#{sample_path}",
              language_id: "ruby",
              version: 1,
              text: File.read(sample_path),
            ),
          }
        )

        requests << lsp_request(
          id: "complete",
          method: :'textDocument/completion',
          kind: Hash,
          params: {
            textDocument: lsp(
              :text_document_identifier,
              uri: "file://#{sample_path}",
            ),
            position: lsp(
              :position,
              line: 0,
              character: 2,
            ),
            context: lsp(
              :completion_context,
              trigger_kind: 1,
              trigger_character: nil,
            ),
          }
        )

        requests << lsp_request(
          id: "test-new",
          method: :'textDocument/didOpen',
          kind: :'did_open_text_document',
          params: {
            text_document: lsp(
              :text_document_item,
              uri: "file://#{sample_path}",
              language_id: "ruby",
              version: 1,
              text: File.read(sample_path),
            ),
          }
        )

      end

      puts error
      puts messages
      messages.each do |message|
        expect(message).not_to have_key(:error)
      end
    end


  end
end
