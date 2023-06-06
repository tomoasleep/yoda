module Yoda
  class Server
    module Providers
      class WorkspaceDidChangeConfiguration < Base
        def self.provider_method
          :'workspace/didChangeConfiguration'
        end

        def provide(params)
          client_config = Store::Config.from_client_configuration(params[:settings])
          session.workspaces.each do |workspace|
            workspace.project.config = workspace.project.config.merge(client_config)
          end

          NO_RESPONSE
        end
      end
    end
  end
end
