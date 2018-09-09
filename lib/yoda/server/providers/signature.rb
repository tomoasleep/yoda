module Yoda
  class Server
    module Providers
      class Signature < Base
        def self.provider_method
          :'textDocument/signatureHelp'
        end

        # @param params [Hash]
        def provide(params)
          notifier.busy(type: :text_document_signature_help) do
            calculate(params[:text_document][:uri], params[:position])
          end
        end

        private

        # @params uri [String]
        # @params position [{Symbol => Integer}]
        def calculate(uri, position)
          source = session.file_store.get(uri)
          location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])
          cut_source = Parsing::SourceCutter.new(source, location).error_recovered_source

          signature_worker = Evaluation::SignatureDiscovery.new(session.registry, cut_source, location)

          functions = signature_worker.method_candidates
          create_signature_help(functions)
        end

        # @param code_objects [Array<Model::FunctionSignatures::Base>]
        def create_signature_help(functions)
          signatures = functions.map { |func| Model::Descriptions::FunctionDescription.new(func) }
          LanguageServer::Protocol::Interface::SignatureHelp.new(
            signatures: signatures.map { |signature| create_signature_info(signature) },
          )
        end

        # @param signature [Evaluation::Descriptions::FunctionDescription]
        def create_signature_info(signature)
          LanguageServer::Protocol::Interface::SignatureInformation.new(
            label: signature.title.to_s,
            documentation: signature.to_markdown,
            parameters: signature.parameter_names.map do |parameter|
              LanguageServer::Protocol::Interface::ParameterInformation.new(
                label: parameter,
              )
            end,
          )
        end
      end
    end
  end
end
