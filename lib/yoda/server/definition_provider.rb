module Yoda
  class Server
    class DefinitionProvider
      # @type Session
      attr_reader :session

      # @param session [Session]
      def initialize(session)
        @session = session
      end

      # @param uri      [String]
      # @param position [{Symbol => Integer}]
      # @param include_declaration [Boolean]
      def provide(uri, position, include_declaration = false)
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
        LSP::Interface::Location.new(
          uri: session.uri_of_path(path),
          range: LSP::Interface::Range.new(Parsing::Range.new(location, location).to_language_server_protocol_range),
        )
      end
    end
  end
end
