module Yoda
  class Server
    module Providers
      class WorkspaceDidCreateFiles < Base
        def self.provider_method
          :'workspace/didCreateFiles'
        end

        # @param params [LanguageServer::Protocol::Interface::CreateFilesParams]
        def provide(params)
          files = params[:files]
          files.each do |file|
            session.read_source(file[:uri])
          end

          NO_RESPONSE
        end
      end
    end
  end
end
