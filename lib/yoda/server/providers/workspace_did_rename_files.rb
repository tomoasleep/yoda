module Yoda
  class Server
    module Providers
      class WorkspaceDidRenameFiles < Base
        def self.provider_method
          :'workspace/didRenameFiles'
        end

        # @param params [LanguageServer::Protocol::Interface::DeleteFilesParams]
        def provide(params)
          files = params[:files]
          files.each do |file|
            session.remove_source(uri: file[:old_uri])
            session.read_source(file[:new_uri])
          end

          NO_RESPONSE
        end
      end
    end
  end
end
