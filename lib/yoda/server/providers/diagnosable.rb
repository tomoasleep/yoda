module Yoda
  class Server
    module Providers
      module Diagnosable
        # @param uri [String] The document uri to diagnose.
        def diagnose(uri)
          workspace = session.workspace_for(uri)
          source = workspace.read_at(uri)
          diagnose = Services::Diagnose.from_source(environment: session.project.environment, source: source)

          if session.project.config.diagnose_types?
            diagnostics =
              diagnose.diagnostics.map do |diagnostic|
                LanguageServer::Protocol::Interface::Diagnostic.new(
                  range: diagnostic.range.to_language_server_protocol_range,
                  severity: LanguageServer::Protocol::Constant::DiagnosticSeverity::WARNING,
                  message: diagnostic.message,
                )
              end

            publish_diagnostics = LanguageServer::Protocol::Interface::PublishDiagnosticsParams.new(
              uri: uri,
              diagnostics: diagnostics,
            )
            notifier.publish_diagnostics(publish_diagnostics)
          end
        end

        # @param uri [String] The document uri to diagnose.
        def diagnose_async(uri)
          async(id: "diagnostics_#{uri}") do
            notifier.busy(type: 'diagnose', id: "diagnostics_#{uri}") { diagnose(uri) }
          end
        end
      end
    end
  end
end
