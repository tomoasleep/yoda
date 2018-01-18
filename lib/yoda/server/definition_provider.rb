module Yoda
  class Server
    class DefinitionProvider
      attr_reader :client_info

      # @param client_info [ClientInfo]
      def initialize(client_info)
        @client_info = client_info
      end

      # @param uri      [String]
      # @param position [{Symbol => Integer}]
      # @param include_declaration [Boolean]
      def provide(uri, position, include_declaration = false)
        source = client_info.file_store.get(uri)
        location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])

        reference_worker = Evaluation::FindDefinition.new(client_info.registry, source, location)

        references = reference_worker.current_const_references
        references.map { |(path, line)| create_location(path, line) }
      end

      # @param path [String]
      # @param line [Integer]
      def create_location(path, line)
        location = Parsing::Location.new(row: line - 1, column: 0)
        LSP::Interface::Location.new(
          uri: client_info.uri_of_path(path),
          range: LSP::Interface::Range.new(Parsing::Range.new(location, location).to_language_server_protocol_range),
        )
      end
    end
  end
end