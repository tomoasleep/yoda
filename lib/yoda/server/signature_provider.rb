module Yoda
  class Server
    class SignatureProvider
      attr_reader :client_info

      # @param client_info [ClientInfo]
      def initialize(client_info)
        @client_info = client_info
      end

      # @param uri      [String]
      # @param position [{Symbol => Integer}]
      def provide(uri, position)
        source = client_info.file_store.get(uri)
        location = Parsing::Location.of_language_server_protocol_position(line: position[:line], character: position[:character])
        cut_source = Parsing::SourceCutter.new(source, location).error_recovered_source

        signature_worker = Evaluation::SignatureDiscovery.new(client_info.registry, cut_source, location)

        functions = signature_worker.method_candidates
        create_signature_help(functions)
      end

      # @param code_objects [Array<Store::Functions::Base>]
      def create_signature_help(functions)
        signatures =
          functions
            .map { |function| function.overloads.empty? ? [function] : function.overloads }
            .flatten
            .map { |func| Evaluation::Descriptions::FunctionDescription.new(func) }
        LSP::Interface::SignatureHelp.new(
          signatures: signatures.map { |signature| create_signature_info(signature) },
        )
      end

      # @param signature [Evaluation::Descriptions::FunctionDescription]
      def create_signature_info(signature)
        LSP::Interface::SignatureInformation.new(
          label: signature.title.to_s,
          documentation: signature.to_markdown,
          parameters: signature.parameter_names.map do |parameter|
            LSP::Interface::ParameterInformation.new(
              label: parameter,
            )
          end,
        )
      end
    end
  end
end
