module Yoda
  module Services
    class CodeCompletion
      # @abstract
      # Base class of completion candidates providers for code completion.
      # This class bridges analysis features such as syntastic analysis {#source_analyzer} and symbolic execiton {#evaluator}.
      class BaseProvider
        # @return [Store::Registry]
        attr_reader :registry

        # @return [Parsing::SourceAnalyzer]
        attr_reader :source_analyzer

        # @return [Evaluator]
        attr_reader :evaluator

        # @param registry [Store::Registry]
        # @param source_analyzer [Parsing::SourceAnalyzer]
        # @param evaluator [Evaluator]
        def initialize(registry, source_analyzer, evaluator)
          @registry = registry
          @source_analyzer = source_analyzer
          @evaluator = evaluator
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

        # @return [::Parser::AST::Node]
        def ast
          source_analyzer.ast
        end

        # @return [Parsing::Location]
        def location
          source_analyzer.location
        end

        # @return [::Parser::AST::Node, nil]
        def current_node
          @current_node ||= source_analyzer.nodes_to_current_location_from_root.last
        end
      end
    end
  end
end
