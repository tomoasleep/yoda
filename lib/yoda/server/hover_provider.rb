module Yoda
  class Server
    class HoverProvider
      attr_reader :session

      # @param session [Session]
      def initialize(session)
        @session = session
      end

      # @param uri      [String]
      # @param position [{Symbol => Integer}]
      def request_hover(uri, position)
        source = session.file_store.get(uri)
        location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])

        node_worker = Evaluation::CurrentNodeExplain.new(session.registry, source, location)

        current_node_signature = node_worker.current_node_signature
        create_hover(current_node_signature) if current_node_signature
      end

      # @param signature [Evaluation::NodeSignature]
      def create_hover(signature)
        LSP::Interface::Hover.new(
          contents: signature.descriptions.map { |value| create_hover_text(value) },
          range: LSP::Interface::Range.new(signature.node_range.to_language_server_protocol_range),
        )
      end

      # @param description [Evaluation::Descriptions::Base]
      # @return [String]
      def create_hover_text(description)
        description.to_markdown
      end
    end
  end
end
