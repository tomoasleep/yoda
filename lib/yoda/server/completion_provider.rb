module Yoda
  class Server
    class CompletionProvider
      attr_reader :client_info

      # @param client_info [ClientInfo]
      def initialize(client_info)
        @client_info = client_info
      end

      # @param uri      [String]
      # @param position [{Symbol => Integer}]
      def complete(uri, position)
        source = client_info.file_store.get(uri)
        location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])
        cut_source = Parsing::SourceCutter.new(source, location).error_recovered_source
        method_analyzer = Parsing::MethodAnalyzer.from_source(client_info.registry, cut_source, location)

        code_objects = method_analyzer.complete
        range = method_analyzer.method_selector_range

        LSP::Interface::CompletionList.new(
          is_incomplete: false,
          items: code_objects.map { |code_object| create_completion_item(code_object, range) },
        )
      end

      # @param code_object [YARD::CodeObjects::MethodObject]
      # @param range       [Parsing::Range]
      def create_completion_item(code_object, range)
        return nil unless range

        function = Store::Function.new(code_object)
        LSP::Interface::CompletionItem.new(
          label: code_object.name.to_s,
          kind: LSP::Constant::CompletionItemKind::METHOD,
          detail: code_object.path,
          documentation: code_object.docstring,
          sort_text: code_object.name.to_s,
          text_edit: LSP::Interface::TextEdit.new(
            range: LSP::Interface::Range.new(range.to_language_server_protocol_range),
            new_text: code_object.name.to_s,
          ),
          data: {},
        )
      end
    end
  end
end
