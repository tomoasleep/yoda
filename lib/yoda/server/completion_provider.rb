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

        completion_worker = Evaluation::MethodCompletion.new(client_info.registry, cut_source, location)

        functions = completion_worker.method_candidates
        range = completion_worker.substitution_range
        return nil unless range

        LSP::Interface::CompletionList.new(
          is_incomplete: false,
          items: functions.map { |function| create_completion_item(function, range) },
        )
      end

      # @param code_object [Store::Function]
      # @param range       [Parsing::Range]
      def create_completion_item(function, range)
        description = Evaluation::Descriptions::FunctionDescription.new(function)
        LSP::Interface::CompletionItem.new(
          label: function.code_object.name.to_s,
          kind: LSP::Constant::CompletionItemKind::METHOD,
          detail: description.title,
          documentation: description.to_markdown,
          sort_text: function.code_object.name.to_s,
          text_edit: LSP::Interface::TextEdit.new(
            range: LSP::Interface::Range.new(range.to_language_server_protocol_range),
            new_text: function.code_object.name.to_s,
          ),
          data: {},
        )
      end
    end
  end
end
