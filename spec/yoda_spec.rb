require 'spec_helper'
require 'support/helpers/server_helper'

RSpec.describe Yoda do
  let(:executable) { File.expand_path("../exe/yoda", __dir__) }
  let(:fixture_path) { File.expand_path("./support/fixtures", __dir__) }
  
  describe "server" do
    include ServerHelper

    let(:command) { "#{executable} server" }

    it "can launch" do
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
      end

      puts error
      expect(messages[0]).not_to have_key(:error)
    end


  end
end
