module Yoda
  class Server
    module Providers
      class Signature < Base
        include WithTimeout

        def self.provider_method
          :'textDocument/signatureHelp'
        end

        # @param params [Hash]
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

        # @params uri [String]
        # @params position [{Symbol => Integer}]
        def calculate(uri, position)
          workspace = session.workspace_for(uri)
          source = workspace.read_at(uri)
          location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])
          cut_source = Parsing.fix_parse_error(source: source, location: location)

          signature_worker = Services::SignatureDiscovery.from_source(environment: workspace.project.environment, source: cut_source, location: location)

          functions = signature_worker.method_candidates
          argument_number = signature_worker.argument_number
          create_signature_help(functions, argument_number)
        end

        # @param code_objects [Array<Model::FunctionSignatures::Base>]
        # @param argument_number [Integer, nil]
        def create_signature_help(functions, argument_number)
          signatures = functions.map { |func| Model::Descriptions::FunctionDescription.new(func) }
          LanguageServer::Protocol::Interface::SignatureHelp.new(
            signatures: signatures.map { |signature| create_signature_info(signature) },
            active_parameter: argument_number,
          )
        end

        # @param signature [Services::Descriptions::FunctionDescription]
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
