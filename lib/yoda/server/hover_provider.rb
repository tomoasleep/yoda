module Yoda
  class Server
    class HoverProvider
      attr_reader :client_info

      # @param client_info [ClientInfo]
      def initialize(client_info)
        @client_info = client_info
      end

      # @param uri      [String]
      # @param position [{Symbol => Integer}]
      def request_hover(uri, position)
        source = client_info.file_store.get(uri)
        location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])

        node_worker = Evaluation::CurrentNodeExplain.new(client_info.registry, source, location)

        current_node_values = node_worker.current_node_values
        current_node_range = node_worker.current_node_range

        create_hover(current_node_values, current_node_range)
      end

      # @param values [Array<Store::Values::Base>]
      # @param range  [Parsing::Range, nil]
      def create_hover(values, range)
        return nil unless range

        LSP::Interface::Hover.new(
          contents: values.map { |value| create_hover_text(value) },
          range: LSP::Interface::Range.new(range.to_language_server_protocol_range),
        )
      end

      # @param code_object [Store::Values::Base]
      # @return [String]
      def create_hover_text(code_object)
        code_object.path
      end
    end
  end
end
