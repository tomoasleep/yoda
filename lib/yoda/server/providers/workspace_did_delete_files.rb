module Yoda
  class Server
    module Providers
      class WorkspaceDidDeleteFiles < Base
        def self.provider_method
          :'workspace/didDeleteFiles'
        end

        # @param params [LanguageServer::Protocol::Interface::DeleteFilesParams]
        def provide(params)
          files = params[:files]
          files.each do |file|
            session.remove_source(uri: file[:uri])
          end

          NO_RESPONSE
        end
      end
    end
  end
end
