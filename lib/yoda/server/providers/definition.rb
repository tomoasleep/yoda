module Yoda
  class Server
    module Providers
      class Definition < Base
        def self.provider_method
          :'textDocument/definition'
        end

        def provide(params)
          calculate(params[:text_document][:uri], params[:position])
        end

        private

        # @param uri      [String]
        # @param position [{Symbol => Integer}]
        # @param include_declaration [Boolean]
        def calculate(uri, position, include_declaration = false)
          source = session.file_store.get(uri)
          location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])

          node_worker = Evaluation::CurrentNodeExplain.new(session.registry, source, location)
          references = node_worker.defined_files
          references.map { |(path, line, column)| create_location(path, line, column) }
        end

        # @param path [String]
        # @param line [Integer]
        # @param column [Integer]
        def create_location(path, line, column)
          location = Parsing::Location.new(row: line - 1, column: column)
          LanguageServer::Protocol::Interface::Location.new(
            uri: session.uri_of_path(path),
            range: LanguageServer::Protocol::Interface::Range.new(Parsing::Range.new(location, location).to_language_server_protocol_range),
          )
        end
      end
    end
  end
end
