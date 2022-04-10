module Yoda
  class Server
    class ServerController
      class Capability
        # @param capability [LanguageServer::Protocol::Interface::ClientCapabilities, nil]
        def initialize(capability = nil)
          receive_client_capability(capability)
        end

        # @param capability [LanguageServer::Protocol::Interface::ClientCapabilities, Hash, nil]
        def receive_client_capability(capability)
          capability = capability&.to_hash
          return unless capability

          @work_done_progress = capability.dig(:window, :work_done_progress)

          Logger.instance.debug(self)
        end

        # @return [Boolean]
        def support_work_done_progress?
          !!@work_done_progress
        end
      end
    end
  end
end
