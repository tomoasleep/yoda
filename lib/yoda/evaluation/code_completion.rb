module Yoda
  module Evaluation
    class CodeCompletion
      require 'yoda/evaluation/code_completion/base_provider'
      require 'yoda/evaluation/code_completion/method_provider'
      require 'yoda/evaluation/code_completion/variable_provider'
      require 'yoda/evaluation/code_completion/const_provider'

      # @return [Store::Registry]
      attr_reader :registry

      # @return [String]
      attr_reader :source

      # @return [Parsing::Location]
      attr_reader :location

      # @param registry [Store::Registry]
      # @param source   [String]
      # @param location [Parsing::Location]
      def initialize(registry, source, location)
        @registry = registry
        @source = source
        @location = location
      end

      # @return [true, false]
      def valid?
        providers.any?(&:providable?)
      end

      # @return [Array<Model::CompletionItem>]
      def candidates
        providers.select(&:providable?).map(&:candidates).flatten
      end

      private

      # @return [Array<CodeCompletion::BaseProvider>]
      def providers
        [method_provider, variable_provider, const_provider]
      end

      # @return [Parsing::SourceAnalyzer]
      def source_analyzer
        @source_analyzer ||= Parsing::SourceAnalyzer.from_source(source, location)
      end

      # @return [MethodProvider]
      def method_provider
        @method_provider ||= MethodProvider.new(registry, source_analyzer)
      end

      # @return [VariableProvider]
      def variable_provider
        @variable_provider ||= VariableProvider.new(registry, source_analyzer)
      end

      # @return [ConstantProvider]
      def const_provider
        @constant_provider ||= ConstProvider.new(registry, source_analyzer)
      end
    end
  end
end
