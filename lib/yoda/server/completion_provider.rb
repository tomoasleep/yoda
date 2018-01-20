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
        return nil unless completion_worker.valid?
        range = completion_worker.substitution_range

        LSP::Interface::CompletionList.new(
          is_incomplete: false,
          items: completion_worker.candidates.map { |description| create_completion_item(description, range) },
        )
      rescue ::Parser::SyntaxError
        nil
      end

      # @param source   [String]
      # @param location [Parsing::Location]
      # @return [LanguageServerProtocol::Interface::CompletionList, nil]
      def complete_from_cut_source(source, location)
        cut_source = Parsing::SourceCutter.new(source, location).error_recovered_source
        method_completion_worker = Evaluation::MethodCompletion.new(client_info.registry, cut_source, location)
        functions = method_completion_worker.method_candidates
        range = method_completion_worker.substitution_range
        return nil unless range

        LSP::Interface::CompletionList.new(
          is_incomplete: false,
          items: functions.map { |function| create_completion_item(Evaluation::Descriptions::FunctionDescription.new(function), range) },
        )
      end

      # @param description [Evaluation::Descriptions::Base]
      # @param range       [Parsing::Range]
      def create_completion_item(description, range)
        LSP::Interface::CompletionItem.new(
          label: description.sort_text,
          kind: LSP::Constant::CompletionItemKind::METHOD,
          detail: description.title,
          documentation: description.to_markdown,
          sort_text: description.sort_text,
          text_edit: LSP::Interface::TextEdit.new(
            range: LSP::Interface::Range.new(range.to_language_server_protocol_range),
            new_text: description.sort_text,
          ),
          data: {},
        )
      end
    end
  end
end
