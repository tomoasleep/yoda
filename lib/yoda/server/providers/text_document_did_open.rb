module Yoda
  class Server
    module Providers
      class TextDocumentDidOpen < Base
        def self.provider_method
          :'textDocument/didOpen'
        end

        def provide(params)
          uri = params[:text_document][:uri]
          text = params[:text_document][:text]
          session.file_store.store(uri, text)

          NO_RESPONSE
        end
      end
    end
  end
end
