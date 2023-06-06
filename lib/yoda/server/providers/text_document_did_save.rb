require_relative 'diagnosable'

module Yoda
  class Server
    module Providers
      class TextDocumentDidSave < Base
        include Diagnosable

        def self.provider_method
          :'textDocument/didSave'
        end

        def provide(params)
          uri = params[:text_document][:uri]

          session.reparse_doc(uri)

          diagnose_async(uri)

          NO_RESPONSE
        end
      end
    end
  end
end
