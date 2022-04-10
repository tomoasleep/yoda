require 'spec_helper'
require 'support/helpers/server_helper'
require 'support/helpers/executable_helper'

RSpec.describe Yoda do
  include ExecutableHelper
  let(:executable) { yoda_exe_path }

  describe "server" do
    include ServerHelper

    let(:command) { "#{executable} server --log-level=trace" }
    let(:fixture_uri) { "file://#{File.absolute_path(fixture_path)}" }

    shared_examples "can launch" do
      it "can launch" do
        messages, error, status = ServerHelper::Client.run(command) do |client|
          client << lsp_request(
            id: "init",
            method: :initialize,
            params: {
              process_id: nil,
              root_uri: fixture_uri,
              capabilities: lsp(:client_capabilities),
            },
          )

          message = client.read until message.nil? || message[:id] == "init"
        end

        expect(messages).not_to include(have_key(:error))
        expect(messages).to include(a_hash_including(id: "init", result: have_key(:capabilities)))
      end
    end

    shared_examples "can open file" do
      it "can open file" do
        messages, error, status = ServerHelper::Client.run(command) do |client|
          client << lsp_request(
            id: "init",
            method: :initialize,
            params: {
              process_id: nil,
              root_uri: nil,
              capabilities: lsp(:client_capabilities),
            }
          )

          message = client.read until message.nil? || message[:id] == "init"

          client << lsp_request(
            id: "test-new",
            method: :initialized,
            params: {}
          )

          client << lsp_request(
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

        expect(messages).not_to include(have_key(:error))
      end
    end

    shared_examples "can complete" do
      it "can complete" do
        messages, error, status = ServerHelper::Client.run(command) do |client|
          client << lsp_request(
            id: "init",
            method: :initialize,
            params: {
              process_id: nil,
              root_uri: fixture_uri,
              capabilities: lsp(:client_capabilities),
            }
          )

          message = client.read until message.nil? || message[:id] == "init"

          client << lsp_request(
            id: "test-new",
            method: :initialized,
            params: {}
          )

          client << lsp_request(
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

          client << lsp_request(
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
                line: location.row,
                character: location.column,
              ),
              context: lsp(
                :completion_context,
                trigger_kind: 1,
                trigger_character: nil,
              ),
            }
          )

          client << lsp_request(
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

        expect(messages).not_to include(have_key(:error))
        expect(messages).to include(
          a_hash_including(
            id: "complete",
            result: a_hash_including(
              isIncomplete: false,
              items: including(
                a_hash_including(label: be_a(String)),
              ),
            ),
          ),
        )
      end
    end

    shared_examples "can hover" do
      it "can hover" do
        messages, error, status = ServerHelper::Client.run(command) do |client|
          client << lsp_request(
            id: "init",
            method: :initialize,
            params: {
              process_id: nil,
              root_uri: fixture_uri,
              capabilities: lsp(:client_capabilities),
            }
          )

          message = client.read until message.nil? || message[:id] == "init"

          client << lsp_request(
            id: "initialized",
            method: :initialized,
            params: {}
          )

          client << lsp_request(
            id: "test-new",
            method: :initialized,
            params: {}
          )

          client << lsp_request(
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

          client << lsp_request(
            id: "hover",
            method: :'textDocument/hover',
            kind: Hash,
            params: {
              textDocument: lsp(
                :text_document_identifier,
                uri: "file://#{sample_path}",
              ),
              position: lsp(
                :position,
                line: location.row,
                character: location.column,
              ),
              context: lsp(
                :completion_context,
                trigger_kind: 1,
                trigger_character: nil,
              ),
            }
          )

        end

        expect(messages).not_to include(have_key(:error))
        expect(messages).to include(
          a_hash_including(
            id: "hover",
            result: a_hash_including(
              contents: including(
                have_content(including(label)),
              ),
            ),
          ),
        )
      end
    end

    context "in a project without Gemfile.lock" do
      let(:fixture_path) { File.expand_path("./support/fixtures", __dir__) }
      let(:sample_path) { File.expand_path('./lib/object.rb', fixture_path) }

      include_examples "can launch"
      include_examples "can open file"
      it_behaves_like "can complete" do
        let(:location) { Yoda::Parsing::Location.new(row: 0, column: 2) }
      end
      include_examples "can hover" do
        let(:location) { Yoda::Parsing::Location.new(row: 0, column: 2) }
        let(:label) { "**Object**" }
      end
    end

    context "in a rails project" do
      let(:fixture_path) { File.expand_path("./support/sample_projects/rails_project", __dir__) }
      let(:sample_path) { File.expand_path('./lib/example.rb', fixture_path) }

      def with_unbundled_env(&block)
        if Bundler.respond_to?(:with_unbundled_env)
          Bundler.with_unbundled_env(&block)
        else
          # For backward compatibility (This method is introduced at bundler 2.1.0: https://github.com/rubygems/bundler/pull/6843)
          Bundler.with_clean_env(&block)
        end
      end

      before(:all) do
        require 'bundler'

        path = File.expand_path("./support/sample_projects/rails_project", __dir__)
        Dir.chdir(path) do
          out, status = with_unbundled_env do
            Open3.capture2e("bundle check || bundle install")
          end
          STDERR.puts out
          status.success? || fail("bundle install failed")
        end
      end

      include_examples "can launch"
      include_examples "can open file"
      it_behaves_like "can complete" do
        let(:location) { Yoda::Parsing::Location.new(row: 0, column: 2) }
      end
      include_examples "can hover" do
        let(:location) { Yoda::Parsing::Location.new(row: 0, column: 2) }
        let(:label) { "**Rails**" }
      end
    end
  end
end
