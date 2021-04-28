module Yoda
  class Server
    module Providers
      class Definition < Base
        include WithTimeout

        def self.provider_method
          :'textDocument/definition'
        end

        def provide(params)
          calculate(params[:text_document][:uri], params[:position])
        end

        private

        def timeout
          10
        end

        def timeout_message(params)
          uri = params[:text_document][:uri]
          position = params[:position]

          "#{self.class.provider_method}: #{uri}:#{position[:line]}:#{position[:character]}"
        end

        # @param uri      [String]
        # @param position [{Symbol => Integer}]
        # @param include_declaration [Boolean]
        def calculate(uri, position, include_declaration = false)
          workspace = session.workspace_for(uri)
          source = workspace.file_store.get(uri)
          location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])

          session.workspaces.each do |workspace|
            next unless workspace.suburi?(uri)

            node_worker = Services::CurrentNodeExplain.from_source(registry: workspace.project.registry, source: source, location: location)

            references = node_worker.current_node_signature.defined_files
            locations = references.map { |(path, line, column)| create_location(workspace.uri_of_path(path), line, column) }

            return locations unless locations.empty?
          end

          []
        end
        
        # @param path [String]
        # @param line [Integer]
        # @param column [Integer]
        def create_location(uri, line, column)
          location = Parsing::Location.new(row: line - 1, column: column)
          LanguageServer::Protocol::Interface::Location.new(
            uri: uri,
            range: LanguageServer::Protocol::Interface::Range.new(**Parsing::Range.new(location, location).to_language_server_protocol_range),
          )
        end
      end
    end
  end
end
