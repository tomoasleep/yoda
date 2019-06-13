module Yoda
  class Server
    module Providers
      require 'yoda/server/providers/base'
      require 'yoda/server/providers/with_timeout'

      require 'yoda/server/providers/completion'
      require 'yoda/server/providers/signature'
      require 'yoda/server/providers/hover'
      require 'yoda/server/providers/definition'
      require 'yoda/server/providers/text_document_did_change'
      require 'yoda/server/providers/text_document_did_open'
      require 'yoda/server/providers/text_document_did_save'

      CLASSES = [
        Completion,
        Definition,
        Hover,
        Signature,
        TextDocumentDidChange,
        TextDocumentDidOpen,
        TextDocumentDidSave,
      ].freeze

      class << self
        # @param method [Symbol]
        # @param notifier [Notifier]
        # @param session [Session]
        # @return [Class<Providers::Base>, nil]
        def build_provider(method:, notifier:, session:)
          find_provider_class(method)&.new(notifier: notifier, session: session)
        end

        # @param method [Symbol]
        # @return [Class<Providers::Base>, nil]
        def find_provider_class(method)
          CLASSES.find { |provider_class| provider_class.provide?(method) }
        end
      end
    end
  end
end
