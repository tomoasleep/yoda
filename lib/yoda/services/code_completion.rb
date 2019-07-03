module Yoda
  module Services
    class CodeCompletion
      require 'yoda/services/code_completion/base_provider'
      require 'yoda/services/code_completion/method_provider'
      require 'yoda/services/code_completion/local_variable_provider'
      require 'yoda/services/code_completion/const_provider'

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
        unify(providers.select(&:providable?).map(&:candidates).flatten)
      end

      private

      def unify(candidates)
        candidates.each_with_object({}) { |candidate, memo| memo.update(candidate.sort_text => candidate) { |_key, old_value, new_value| old_value.merge(new_value) } }.values
      end

      # @return [Array<CodeCompletion::BaseProvider>]
      def providers
        [local_variable_provider, method_provider, const_provider]
      end

      # @return [MethodProvider]
      def method_provider
        @method_provider ||= MethodProvider.new(registry, ast, location, evaluator)
      end

      # @return [LocalVariableProvider]
      def local_variable_provider
        @local_variable_provider ||= LocalVariableProvider.new(registry, ast, location, evaluator)
      end

      # @return [ConstantProvider]
      def const_provider
        @constant_provider ||= ConstProvider.new(registry, ast, location, evaluator)
      end

      # @return [Yoda::AST::Vnode]
      def ast
        @ast ||= Yoda::Parsing::Parser.new.parse(source)
      end

      # @return [Typing::Inferencer::Tracer]
      def evaluator
        @evaluator ||= Evaluator.new(ast: ast, registry: registry)
      end
    end
  end
end
