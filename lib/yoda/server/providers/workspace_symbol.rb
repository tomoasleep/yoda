require "yoda/server/providers/reportable_progress"

module Yoda
  class Server
    module Providers
      class WorkspaceSymbol < Base
        include ReportableProgress

        def self.provider_method
          :'workspace/symbol'
        end

        def provide(params)
          query = params[:query]

          results = in_progress(params, title: "Searching symbol") do |reporter|
            matched_items(query).each do |item|
              reporter.send_result([item])
            end
          end

          results.flatten(1)
        end

        private

        def matched_items(query_string)
          Enumerator.new do |yielder|
            session.workspaces.each do |workspace|
              query = Store::Query::FindWorkspaceObjects.new(workspace.project.registry)
              query.select(query_string).each do |item|
                yielder << to_symbol_information(workspace: workspace, item: item)
              end
            end
          end
        end

        # @param workspace [Workspace]
        # @param item [Store::Objects::Base]
        # @return [LanguageServer::Protocol::Interface::SymbolInformation]
        def to_symbol_information(workspace:, item:)
          path, line, column = item.primary_source
          LanguageServer::Protocol::Interface::SymbolInformation.new(
            name: item.name,
            kind: language_server_kind_of(item),
            location: create_location(workspace.uri_of_path(path), line, column),
            
          )

        end

        # @param path [String]
        # @param line [Integer]
        # @param column [Integer]
        def create_location(uri, line, column)
          location = Parsing::Location.new(row: line - 1, column: column)
          LanguageServer::Protocol::Interface::Location.new(
            uri: uri,
            range: LanguageServer::Protocol::Interface::Range.new(**Parsing::Range.new(location, location).to_language_server_protocol_range),
          )
        end

        # @param item [Store::Objects::Base]
        def language_server_kind_of(item)
          case item.kind
          when :constant, :value_object
            LanguageServer::Protocol::Constant::SymbolKind::CONSTANT
          when :method
            LanguageServer::Protocol::Constant::SymbolKind::METHOD
          when :class, :meta_class
            LanguageServer::Protocol::Constant::SymbolKind::CLASS
          when :module
            LanguageServer::Protocol::Constant::SymbolKind::CLASS
          else
            Logger.warn("Unexpected kind for symbol: #{item}")
            LanguageServer::Protocol::Constant::SymbolKind::NULL
          end
        end
      end
    end
  end
end
