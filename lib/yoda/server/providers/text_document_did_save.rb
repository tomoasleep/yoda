module Yoda
  class Server
    module Providers
      class TextDocumentDidSave < Base
        def self.provider_method
          :'textDocument/didSave'
        end

        def provide(params)
          uri = params[:text_document][:uri]

          session.reparse_doc(uri)

          NO_RESPONSE
        end
      end
    end
  end
end
