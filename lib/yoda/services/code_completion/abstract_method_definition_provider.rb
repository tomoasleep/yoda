module Yoda
  module Services
    class CodeCompletion
      class AbstractMethodDefinitionProvider < BaseProvider
        # @return [true, false]
        def providable?
          !!current_def
        end

        # @return [Array<Model::CompletionItem>]
        def candidates
          method_candidates.map do |method_candidate|
            Model::CompletionItem.new(
              description: Model::Descriptions::FunctionDescription.new(method_candidate),
              range: substitution_range,
              kind: :method,
              priority: priority_for(method_candidate),
            )
          end
        end

        private

        # @return [Range]
        def substitution_range
          return current_def.selector_range if current_send.on_selector?(location)
          return Parsing::Range.new(current_send.next_location_to_dot, current_send.next_location_to_dot) if current_send.on_dot?(location)
          nil
        end

        # @return [Array<Model::FunctionSignatures::Wrapper>]
        def method_candidates
          return [] unless providable?
          @method_candidates ||= instance_type_to_define_method.value.select_method(/\A#{Regexp.escape(index_word)}/, visibility: method_visibility)
        end

        # @return [Array<Symbol>]
        def method_visibility
          if current_def.implicit_receiver?
            %i(public private protected)
          else
            %i(public)
          end
        end

        # @return [Typing::Types::Type, nil]
        def instance_type_to_define_method
          return nil unless current_def
          @receiver_type ||= begin
            case current_def.type
            when :def
              evaluator.receiver_type(current_send).instance_type
            when :defs
              evaluator.receiver_type(current_send)
            end
          end
        end

        # @return [AST::DefNode, AST::DefSingletonNode, nil]
        def current_def
          @current_send ||= %i(def defs).include?(current_node&.type) ? current_node : nil
        end

        # @return [String, nil]
        def index_word
          return nil unless providable?
          @index_word ||= current_def.on_selector?(location) ? current_def.selector_name.slice(0..current_send.offset_in_selector(location)) : ''
        end

        # @param function_signature [FunctionSignatures::Wrapper]
        # @return [Model::SortPriority::Base]
        def priority_for(function_signature)
          if LOW_PRIORITY_NAMESPACES.include?(function_signature.namespace_path)
            Model::SortPriority.low
          else
            Model::SortPriority.none
          end
        end
      end
    end
  end
end
