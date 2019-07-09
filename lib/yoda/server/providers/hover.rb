module Yoda
  class Server
    module Providers
      class Hover < Base
        include WithTimeout

        def self.provider_method
          :'textDocument/hover'
        end

        def provide(params)
          calculate(params[:text_document][:uri], params[:position])
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
          source = session.file_store.get(uri)
          evaluator = Services::Evaluator.new(ast: Parsing::Parser.new.parse(source), registry: session.registry)
          location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])

          node_worker = Services::CurrentNodeExplain.new(evaluator: evaluator, location: location)

          current_node_signature = node_worker.current_node_signature
          create_hover(current_node_signature) if current_node_signature
        end

        # @param signature [Model::NodeSignatures::Base]
        def create_hover(signature)
          LanguageServer::Protocol::Interface::Hover.new(
            contents: signature.descriptions.map { |value| create_hover_text(value) },
            range: LanguageServer::Protocol::Interface::Range.new(signature.node_range.to_language_server_protocol_range),
          )
        end

        # @param description [Model::Descriptions::Base]
        # @return [String, Hash]
        def create_hover_text(description)
          description.markup_content
        end
      end
    end
  end
end
