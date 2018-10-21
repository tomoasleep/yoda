module Yoda
  class Server
    module Providers
      class Completion < Base
        def self.provider_method
          :'textDocument/completion'
        end

        def provide(params)
          uri = params[:text_document][:uri]
          position = params[:position]

          calculate(uri, position)
        end

        def timeout
          10
        end

        private

        # @param uri      [String]
        # @param position [{Symbol => Integer}]
        def calculate(uri, position)
          source = session.file_store.get(uri)
          location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])

          if candidates = comment_complete(source, location)
            return candidates
          end
          complete_from_cut_source(source, location)
        end

        # @param source   [String]
        # @param location [Parsing::Location]
        # @return [LanguageServerProtocol::Interface::CompletionList, nil]
        def comment_complete(source, location)
          ast, comments = Parsing::Parser.new.parse_with_comments(source)
          return nil unless Parsing::Query::CurrentCommentQuery.new(comments, location).current_comment
          completion_worker = Commands::CommentCompletion.new(session.registry, ast, comments, location)
          return nil unless completion_worker.available?

          completion_items = completion_worker.candidates

          LanguageServer::Protocol::Interface::CompletionList.new(
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
          method_completion_worker = Commands::CodeCompletion.new(session.registry, cut_source, location)
          completion_items = method_completion_worker.candidates

          LanguageServer::Protocol::Interface::CompletionList.new(
            is_incomplete: false,
            items: completion_items.map { |completion_item| create_completion_item(completion_item) },
          )
        end

        # @param completion_item [Model::CompletionItem]
        # @return            [LanguageServer::Protocol::Interface::CompletionItem]
        def create_completion_item(completion_item)
          LanguageServer::Protocol::Interface::CompletionItem.new(
            label: completion_item.description.is_a?(Model::Descriptions::FunctionDescription) ? completion_item.description.signature : completion_item.description.sort_text,
            kind: completion_item.language_server_kind,
            detail: completion_item.description.title,
            documentation: completion_item.description.to_markdown,
            sort_text: completion_item.description.sort_text,
            text_edit: LanguageServer::Protocol::Interface::TextEdit.new(
              range: LanguageServer::Protocol::Interface::Range.new(completion_item.range.to_language_server_protocol_range),
              new_text: completion_item.edit_text,
            ),
            data: {},
          )
        end
      end
    end
  end
end
