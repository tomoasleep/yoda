module Yoda
  class Server
    module Providers
      class Completion < Base
        include WithTimeout

        def self.provider_method
          :'textDocument/completion'
        end

        def provide(params)
          uri = params[:text_document][:uri]
          position = params[:position]

          calculate(uri, position)
        end

        private

        def timeout
          10
        end

        def timeout_message(params)
          uri = params[:text_document][:uri]
          position = params[:position]

          "#{self.class.provider_method}: #{uri}:#{position[:line]}:#{position[:character]}"
        end

        # @param uri      [String]
        # @param position [{Symbol => Integer}]
        def calculate(uri, position)
          workspace = session.workspace_for(uri)
          source = workspace.read_at(uri)
          location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])

          Logger.trace("Trying comment completion for #{uri}, #{position}")
          candidates = comment_complete(workspace, source, location)
          return candidates if candidates

          Logger.trace("Trying code completion for #{uri}, #{position}")
          complete_from_cut_source(workspace, source, location)
        end

        # @param workspace [Workspace]
        # @param source   [String]
        # @param location [Parsing::Location]
        # @return [LanguageServerProtocol::Interface::CompletionList, nil]
        def comment_complete(workspace, source, location)
          ast, comments = Parsing.parse_with_comments(source)
          return nil unless Parsing::Query::CurrentCommentQuery.new(comments, location).current_comment
          completion_worker = Services::CommentCompletion.new(workspace.project.environment, ast, comments, location)
          return nil unless completion_worker.available?

          completion_items = completion_worker.candidates

          LanguageServer::Protocol::Interface::CompletionList.new(
            is_incomplete: false,
            items: completion_worker.candidates.map { |completion_item| create_completion_item(completion_item) },
          )
        rescue ::Parser::SyntaxError
          nil
        end

        # @param workspace [Workspace]
        # @param source   [String]
        # @param location [Parsing::Location]
        # @return [LanguageServerProtocol::Interface::CompletionList, nil]
        def complete_from_cut_source(workspace, source, location)
          cut_source = Parsing.fix_parse_error(source: source, location: location)
          method_completion_worker = Services::CodeCompletion.new(workspace.project.environment, cut_source, location)
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
            label: completion_item.label,
            kind: completion_item.language_server_kind,
            detail: completion_item.title,
            documentation: completion_item.to_markdown,
            sort_text: completion_item.sort_text,
            text_edit: LanguageServer::Protocol::Interface::TextEdit.new(
              range: LanguageServer::Protocol::Interface::Range.new(**completion_item.language_server_range),
              new_text: completion_item.edit_text,
            ),
            data: {},
          )
        end
      end
    end
  end
end
