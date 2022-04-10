require 'spec_helper'

RSpec.describe Yoda::Server::Providers::WorkspaceDidDeleteFiles do
  include FileUriHelper

  let(:session) { Yoda::Server::Session.from_root_uri(fixture_root_uri, server_controller: server_controller) }
  let(:writer) { instance_double('Yoda::Server::ConcurrentWriter').as_null_object }
  let(:server_controller) { Yoda::Server::ServerController.new(writer: writer) }
  let(:provider) { described_class.new(session: session) }

  def partial_results
    @partial_results ||= []
  end

  describe '#provide' do
    before do
      session.setup
    end

    let(:uri) { file_uri('lib/sample.rb') }

    let(:params) do
      {
        files: [
          {
            uri: uri,
          },
        ],
      }
    end

    subject { provider.provide(params) }

    it 'reads the source' do
      id = File.expand_path('lib/sample.rb', fixture_root)
      local_store = session.workspaces.first.project.registry.local_store

      expect(local_store.find_file_patch(id)).not_to be_nil
      subject
      expect(local_store.find_file_patch(id)).to be_nil

      expect(subject).to eq(:no_response)
    end
  end
end
