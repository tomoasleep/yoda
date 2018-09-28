require 'spec_helper'

RSpec.describe Yoda::Server do
  include FileUriHelper

  let(:server) do
    described_class.new(
      writer: writer,
      reader: reader_class.new,
    )
  end

  let(:reader_class) do
    example_requests = requests
    Class.new { define_method(:read) { |&blk| example_requests.map { |request| blk.call(request) } } }
  end
  let(:requests) { [] }
  let(:writer) { instance_double('Writer') }

  describe '#run' do
    subject { server.run }
    let(:id) { SecureRandom.hex(10) }

    describe 'with initialize method' do
      let(:requests) do
        [
          { id: id, method: 'initialize', params: params },
        ]
      end
      let(:params) do
        {
          root_uri: fixture_root_uri,
        }
      end

      it 'sends capabilities' do
        allow(writer).to receive(:write)
        expect(writer).to receive(:write).with(
          id: id,
          result: be_instance_of(LanguageServer::Protocol::Interface::InitializeResult),
        )

        subject
      end
    end
  end
end
