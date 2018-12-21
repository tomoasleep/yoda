module Yoda
  module Services
    class CodeCompletion
      class LocalVariableProvider < BaseProvider

        # @return [true, false]
        def providable?
          return false unless current_node
          return true if %i(ivar lvar gvar cvar).include?(current_node.type)
          return true if current_node.type == :send && !current_node.children.first
          false
        end

        # @return [Array<Model::CompletionItem>]
        def candidates
          local_variables.select { |variable_name, _| variable_name.to_s.start_with?(index_word) }.map do |variable_name, type_expression|
            Model::CompletionItem.new(
              description: Model::Descriptions::VariableDescription.new(variable: variable_name, type: type_expression),
              range: substitution_range,
              kind: :variable,
            )
          end
        end

        private

        # @return [Hash{Symbol => Model::TypeExpressions::Base}]
        def local_variables
          @local_variables ||= evaluator.context_variable_types(current_node) || {}
        end

        # @return [Range]
        def substitution_range
          Parsing::Range.of_ast_location(current_node.location.expression)
        end

        # @return [String, nil]
        def index_word
          return nil unless providable?
          @index_word ||= begin
            case current_node.type
            when :ivar, :lvar, :gvar, :cvar
              current_node.children.first.to_s
            when :send
              current_node.children[1].to_s
            end
          end
        end
      end
    end
  end
end
