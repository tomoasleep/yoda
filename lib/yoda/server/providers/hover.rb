module Yoda
  class Server
    module Providers
      class Hover < Base
        def self.provider_method
          :'textDocument/hover'
        end

        def provide(params)
          calculate(params[:text_document][:uri], params[:position])
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

          node_worker = Evaluation::CurrentNodeExplain.new(session.registry, source, location)

          current_node_signature = node_worker.current_node_signature
          create_hover(current_node_signature) if current_node_signature
        end

        # @param signature [Evaluation::NodeSignature]
        def create_hover(signature)
          LanguageServer::Protocol::Interface::Hover.new(
            contents: signature.descriptions.map { |value| create_hover_text(value) },
            range: LanguageServer::Protocol::Interface::Range.new(signature.node_range.to_language_server_protocol_range),
          )
        end

        # @param description [Evaluation::Descriptions::Base]
        # @return [String]
        def create_hover_text(description)
          description.to_markdown
        end
      end
    end
  end
end
