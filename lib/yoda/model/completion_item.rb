module Yoda
  module Model
    class CompletionItem
      # @return [Descriptions::Base]
      attr_reader :description

      # @return [Parsing::Range]
      attr_reader :range

      # @return [Symbol]
      attr_reader :kind

      # @return [String]
      attr_reader :prefix

      # @param description [Descriptions::Base]
      # @param range       [Parsing::Range]
      # @param kind        [Symbol, nil]
      # @param prefix      [String, nil]
      def initialize(description:, range:, kind: nil, prefix: nil)
        fail ArgumentError, desctiption unless description.is_a?(Descriptions::Base)
        fail ArgumentError, range unless range.is_a?(Parsing::Range)
        fail ArgumentError, kind if !kind.nil? && !available_kinds.include?(kind)
        @description = description
        @range = range
        @kind = kind
        @prefix = prefix || ''
      end

      # @return [String]
      def edit_text
        prefix + description.sort_text
      end

      # @return [Symbol]
      def available_kinds
        %i(method class module constant)
      end

      def language_server_kind
        case kind
        when :constant
          LanguageServer::Protocol::Constant::CompletionItemKind::VALUE
        when :method
          LanguageServer::Protocol::Constant::CompletionItemKind::METHOD
        when :class
          LanguageServer::Protocol::Constant::CompletionItemKind::CLASS
        when :module
          LanguageServer::Protocol::Constant::CompletionItemKind::MODULE
        else
          nil
        end
      end
    end
  end
end
