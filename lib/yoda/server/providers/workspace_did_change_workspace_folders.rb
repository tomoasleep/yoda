module Yoda
  class Server
    module Providers
      class WorkspaceDidChangeWorkspaceFolders < Base
        def self.provider_method
          :'workspace/didChangeWorkspaceFolders'
        end

        def provide(params)
          added_folders = params[:event][:added].map(&method(:to_folder))
          removed_folders = params[:event][:added].map(&method(:to_folder))

          added_folders.each do
            workspace = Workspace.from_workspace_folder(folder)
            session.add_workspace(workspace)
          end

          removed_folders.each do
            session.remove_workspace(id: folder.id)
          end

          NO_RESPONSE
        end

        private

        def to_folder(folder_params)
          LanguageServer::Protocol::Interface::WorkspaceFolder.new(**folder_params)
        end
      end
    end
  end
end
