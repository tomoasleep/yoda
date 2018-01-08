module Yoda
  class Server
    class HoverProvider
      attr_reader :client_info

      def initialize(client_info)
        @client_info = client_info
      end

      def request_hover(uri, position)
        source = client_info.file_store.get(uri)
        location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])
        method_analyzer = Parsing::MethodAnalyzer.from_source(client_info.registry, source, location)

        current_type = method_analyzer.calculate_current_node_type
        current_node_range = method_analyzer.current_node_range

        create_hover(current_type, current_node_range)
      end

      # @param current_type [Store::Types::Base]
      # @param range        [Parsing::Range, nil]
      def create_hover(type, range)
        return nil unless range

        LSP::Interface::Hover.new(
          contents: type.resolve(client_info.registry).map { |code_object| create_hover_text(code_object) },
          range: LSP::Interface::Range.new(range.to_language_server_protocol_range),
        )
      end

      # @param code_object [YARD::CodeObjects::Base, YARD::CodeObjects::Proxy]
      # @return [String]
      def create_hover_text(code_object)
        if code_object.type == :proxy
          "#{code_object.path}"
        else
          "#{code_object.path} #{code_object.signature}"
        end
      end
    end
  end
end
