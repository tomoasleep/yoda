module Yoda
  module Evaluation
    class CodeCompletion
      # @abstract
      # Base class of completion candidates providers for code completion.
      # This class bridges analysis features such as syntastic analysis {#analyzer} and symbolic execiton {#evaluator}.
      class BaseProvider
        # @return [Store::Registry]
        attr_reader :registry

        # @return [Parsing::SourceAnalyzer]
        attr_reader :source_analyzer

        # @param registry [Store::Registry]
        # @param source_analyzer [Parsing::SourceAnalyzer]
        def initialize(registry, source_analyzer)
          @registry = registry
          @source_analyzer = source_analyzer
        end

        # @abstract
        # @return [true, false]
        def providable?
          fail NotImplementedError
        end

        # @abstract
        # @return [Array<Model::CompletionItem>]
        def candidates
          fail NotImplementedError
        end

        private

        # @return [SourceAnalyzer]
        def analyzer
          @analyzer ||= Parsing::SourceAnalyzer.from_source(source, location)
        end

        # @return [Evaluator]
        def evaluator
          @evaluator ||= Evaluator.from_ast(registry, source_analyzer.ast, location)
        end

        # @return [::Parser::AST::Node]
        def ast
          source_analyzer.ast
        end

        # @return [Parsing::Location]
        def location
          source_analyzer.location
        end
      end
    end
  end
end
