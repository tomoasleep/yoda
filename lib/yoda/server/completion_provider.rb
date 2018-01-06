module Yoda
  class Server
    class CompletionProvider
      attr_reader :client_info

      # @param client_info [ClientInfo]
      def initialize(client_info)
        @client_info = client_info
      end

      def complete(uri, position)
        source = client_info.file_store.get(uri)
        location = Parsing::Location.of_language_server_protocol_position(line: position.line, character: position.character)
        method_analyzer = Parsing::MethodAnalyzer.from_source(client_info.registry, source, location)

        code_objects = method_analyzer.complete
        current_node_range = method_analyzer.calculate_current_node_type

        LSP::Interface::CompletionList.new(
          is_incomplete: false,
          items: code_objects.map { |code_object| create_completion_item(code_object, range) },
        )
      end

      # @param code_object [Array<YARD::CodeObjects::MethodObject>]
      # @param range       [Parsing::Range]
      def create_completion_item(code_object, range)
        return nil unless range

        function = Store::Function.new(code_object)
        LSP::Interface::CompletionItem.new(
          label: code_object.signature,
          kind: LSP::Constant::CompletionItemKind::METHOD,
          # detail: 'detail',
          documentation: code_object.docstring,
          sort_text: code_object.name,
          text_edit: LSP::Interface::TextEdit(
            range: LSP::Interface::Range.new(range.to_language_server_protocol_range),
            new_text: code_object.name,
          ),
          data: {},
        )
      end
    end
  end
end
