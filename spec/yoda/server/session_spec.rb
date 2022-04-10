require 'spec_helper'

RSpec.describe Yoda::Server::Session do
  include FileUriHelper

  let(:session) { described_class.from_root_uri(root_uri, server_controller: server_controller) }
  let(:server_controller) { instance_double('Yoda::Server::ServerController').as_null_object }
  let(:root_uri) { fixture_root_uri }

  describe '#workspaces_for' do
    subject { session.workspaces_for(uri) }

    let(:uri) { file_uri('lib/sample.rb') }

    it "returns workspaces for the given uri" do
      expect(subject).to contain_exactly(
        have_attributes(root_uri: root_uri),
      )
    end
  end
end
