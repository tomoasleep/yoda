module Yoda
  module Model
    class CompletionItem
      extend Forwardable

      # @return [Array<Descriptions::Base>]
      attr_reader :descriptions

      # @return [Parsing::Range]
      attr_reader :range

      # @return [Symbol]
      attr_reader :kind

      # @return [String]
      attr_reader :prefix

      # @return [SortPriority::Base, nil]
      attr_reader :priority

      delegate %i(label title to_markdown) => :primary_description

      # @param descriptions [Array<Descriptions::Base>]
      # @param range        [Parsing::Range]
      # @param kind         [Symbol, nil]
      # @param prefix       [String, nil]
      # @param priority     [SortPriority::Base, nil]
      def initialize(description: nil, descriptions: [], range:, kind: nil, prefix: nil, priority: nil)
        fail ArgumentError, description if description && !description.is_a?(Descriptions::Base)
        fail ArgumentError, descriptions unless descriptions.all? { |description| description.is_a?(Descriptions::Base) }
        fail ArgumentError, range unless range.is_a?(Parsing::Range)
        fail ArgumentError, kind if !kind.nil? && !available_kinds.include?(kind)
        @descriptions = ([description] + descriptions).compact
        @range = range
        @kind = kind
        @prefix = prefix || ''
        @priority = priority
      end

      def primary_description
        descriptions.first
      end

      # @return [String]
      def edit_text
        prefix + primary_description.sort_text
      end

      # @return [String]
      def sort_text
        "#{priority&.prefix}#{primary_description.sort_text}"
      end

      # @return [Symbol]
      def available_kinds
        %i(method class module constant variable)
      end

      # @return [Symbol]
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
        when :variable
          LanguageServer::Protocol::Constant::CompletionItemKind::VARIABLE
        else
          nil
        end
      end

      def to_s
        title
      end

      # @return [{Symbol => { Symbol => Integer } }]
      def language_server_range
        range.to_language_server_protocol_range
      end

      # @param function_description [FunctionDescription]
      # @return [FunctionDescription, MultipleFunctionDescription]
      def merge(completion_item)
        self.class.new(
          descriptions: descriptions + completion_item.descriptions,
          range: range,
          kind: kind,
          prefix: prefix,
        )
      end
    end
  end
end
