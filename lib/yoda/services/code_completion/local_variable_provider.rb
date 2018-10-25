module Yoda
  module Services
    class CodeCompletion
      class LocalVariableProvider < BaseProvider

        # @return [true, false]
        def providable?
          return false unless current_node
          return true if %i(ivar lvar gvar).include?(current_node.type)
          return true if current_node.type == :send && !current_node.children.first
          false
        end

        # @return [Array<Model::CompletionItem>]
        def candidates
        end

        private

        # @return [Typing::Traces::Base, nil]
        def current_trace
          @current_trace ||= evaluator.calculate_trace(current_node)
        end

        # @return [Typing::Context]
        def current_context
          current_trace&.context
        end
      end
    end
  end
end
