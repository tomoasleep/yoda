require 'spec_helper'

RSpec.describe Yoda::Server do
  LSP = ::LanguageServer::Protocol
  let(:server) { described_class.new }

  let(:root_path) { File.absolute_path('../support/fixtures', __dir__) }
  let(:init_param) do
    {
      root_uri: "file://#{root_path}",
    }
  end

  describe '#callback' do
    subject { server.callback({ method: :initialize, params: init_param }) }

    it 'returns capabilities' do
      expect(subject).to be_instance_of(LSP::Interface::InitializeResult)
    end
  end

  describe '#handle_initialize' do
    subject { server.handle_initialize(init_param) }

    it 'returns capabilities' do
      expect(subject).to be_instance_of(LSP::Interface::InitializeResult)
    end
  end
end
