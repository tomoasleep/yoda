module Yoda
  class Server
    module Providers
      class TextDocumentDidChange < Base
        def self.provider_method
          :'textDocument/didChange'
        end

        def provide(params)
          uri = params[:text_document][:uri]
          text = params[:content_changes].first[:text]
          session.store_source(uri: uri, source: text)

          NO_RESPONSE
        end
      end
    end
  end
end
