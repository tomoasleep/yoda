module Yoda
  module Services
    class CodeCompletion
      class LocalVariableProvider < BaseProvider

        # @return [true, false]
        def providable?
          return false unless current_node
          return true if index_word
          false
        end

        # @return [Array<Model::CompletionItem>]
        def candidates
          return [] unless providable?
          local_variables.select { |variable_name, _| variable_name.to_s.start_with?(index_word) }.map do |variable_name, type_expression|
            Model::CompletionItem.new(
              description: Model::Descriptions::VariableDescription.new(variable: variable_name, type: type_expression),
              range: substitution_range,
              kind: :variable,
            )
          end
        end

        private

        # @return [Hash{Symbol => Typing::Types::Type}]
        def local_variables
          @local_variables ||= evaluator.context_variable_types(current_node) || {}
        end

        # @return [Range]
        def substitution_range
          current_node.range
        end

        # @return [String, nil]
        def index_word
          @index_word ||= begin
            case current_node.type
            when :ivar, :lvar, :gvar, :cvar
              current_node.name.to_s
            when :send
              current_node.implicit_receiver? && current_node.selector_name.to_s
            end
          end
        end
      end
    end
  end
end
