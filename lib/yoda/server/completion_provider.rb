module Yoda
  class Server
    class CompletionProvider
      # @type ClientInfo
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

        if candidates = comment_complete(source, location)
          return candidates
        end
        complete_from_cut_source(source, location)
      end

      private

      # @param source   [String]
      # @param location [Parsing::Location]
      # @return [LanguageServerProtocol::Interface::CompletionList, nil]
      def comment_complete(source, location)
        ast, comments = Parsing::Parser.new.parse_with_comments(source)
        return nil unless Parsing::Query::CurrentCommentQuery.new(comments, location).current_comment
        completion_worker = Evaluation::CommentCompletion.new(client_info.registry, ast, comments, location)
        return nil unless completion_worker.available?

        completion_items = completion_worker.candidates

        LSP::Interface::CompletionList.new(
          is_incomplete: false,
          items: completion_worker.candidates.map { |completion_item| create_completion_item(completion_item) },
        )
      rescue ::Parser::SyntaxError
        nil
      end

      # @param source   [String]
      # @param location [Parsing::Location]
      # @return [LanguageServerProtocol::Interface::CompletionList, nil]
      def complete_from_cut_source(source, location)
        cut_source = Parsing::SourceCutter.new(source, location).error_recovered_source
        method_completion_worker = Evaluation::CodeCompletion.new(client_info.registry, cut_source, location)
        completion_items = method_completion_worker.candidates
        return nil if completion_items.empty?

        LSP::Interface::CompletionList.new(
          is_incomplete: false,
          items: completion_items.map { |completion_item| create_completion_item(completion_item) },
        )
      end

      # @param completion_item [Model::CompletionItem]
      # @return            [LSP::Interface::CompletionItem]
      def create_completion_item(completion_item)
        LSP::Interface::CompletionItem.new(
          label: completion_item.description.is_a?(Model::Descriptions::FunctionDescription) ? completion_item.description.signature : completion_item.description.sort_text,
          kind: LSP::Constant::CompletionItemKind::METHOD,
          detail: completion_item.description.title,
          documentation: completion_item.description.to_markdown,
          sort_text: completion_item.description.sort_text,
          text_edit: LSP::Interface::TextEdit.new(
            range: LSP::Interface::Range.new(completion_item.range.to_language_server_protocol_range),
            new_text: completion_item.description.sort_text,
          ),
          data: {},
        )
      end
    end
  end
end
