module Yoda
  class Server
    module Providers
      class WorkspaceDidChangeWatchedFiles < Base
        def self.provider_method
          :'workspace/didChangeWatchedFiles'
        end

        # @param params [LanguageServer::Protocol::Interface::DidChangeWatchedFilesParams]
        def provide(params)
          changes = params[:changes]
          changes.each do |change|
            session.read_source(uri: file[:uri])
          end

          NO_RESPONSE
        end
      end
    end
  end
end
