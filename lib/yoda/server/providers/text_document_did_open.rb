module Yoda
  class Server
    module Providers
      class TextDocumentDidOpen < Base
        include Diagnosable

        def self.provider_method
          :'textDocument/didOpen'
        end

        def provide(params)
          uri = params[:text_document][:uri]
          text = params[:text_document][:text]
          session.store_source(uri: uri, source: text)

          diagnose_async(uri)

          NO_RESPONSE
        end
      end
    end
  end
end
