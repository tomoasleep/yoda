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

      # @param code_objects [Array<Store::Function>]
      def create_signature_help(functions)
        signatures = functions.map { |function| function.signatures.empty? ? [function] : function.signatures }.flatten
        LSP::Interface::SignatureHelp.new(
          signatures: signatures.map { |signature| create_signature_info(signature) },
        )
      end

      # @param signature [Store::Function::Signature, Store::Function]
      def create_signature_info(signature)
        LSP::Interface::SignatureInformation.new(
          label: signature.signature.to_s,
          documentation: signature.docstring,
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