module Yoda
  module Services
    class CodeCompletion
      # @abstract
      # Base class of completion candidates providers for code completion.
      # This class bridges analysis features such as syntastic analysis {#source_analyzer} and symbolic execiton {#evaluator}.
      class BaseProvider
        # @return [Model::Environment]
        attr_reader :environment

        # @return [AST::Vnode]
        attr_reader :ast

        # @return [Parsing::Location]
        attr_reader :location

        # @return [Evaluator]
        attr_reader :evaluator

        # @param environment [Model::Environment]
        # @param ast [AST::Vnode]
        # @param location [Parsing::Location]
        # @param evaluator [Evaluator]
        def initialize(environment, ast, location, evaluator)
          @environment = environment
          @ast = ast
          @location = location
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

        # @return [AST::Node, nil]
        def current_node
          @current_node ||= ast.positionally_nearest_child(location)
        end
      end
    end
  end
end
