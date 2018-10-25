module Yoda
  module Services
    class CodeCompletion
      class MethodProvider < BaseProvider
        # @return [true, false]
        def providable?
          !!(current_send)
        end

        # @return [Array<Model::CompletionItem>]
        def candidates
          method_candidates.map do |method_candidate|
            Model::CompletionItem.new(
              description: Model::Descriptions::FunctionDescription.new(method_candidate),
              range: substitution_range,
              kind: :method,
            )
          end
        end

        private

        # @return [Range]
        def substitution_range
          return current_send.selector_range if current_send.on_selector?(location)
          return Parsing::Range.new(current_send.next_location_to_dot, current_send.next_location_to_dot) if current_send.on_dot?(location)
          nil
        end

        # @return [Array<Store::Objects::Method>]
        def method_candidates
          return [] unless providable?
          receiver_values
            .map { |value| Store::Query::FindSignature.new(registry).select(value, /\A#{Regexp.escape(index_word)}/, visibility: method_visibility_of_send_node(current_send)) }
            .flatten
        end

        # @param send_node [Parsing::NodeObjects::SendNode]
        # @return [Array<Symbol>]
        def method_visibility_of_send_node(send_node)
          if send_node.receiver_node
            %i(public)
          else
            %i(public private protected)
          end
        end

        # @return [Array<Store::Objects::Base>]
        def receiver_values
          @receiver_values ||= begin
            if current_receiver_node
              evaluator.calculate_values(current_receiver_node)
            else
              # implicit call for self
              [evaluator.scope_constant]
            end
          end
        end

        # @return [Parsing::NodeObjects::SendNode, nil]
        def current_send
          @current_send ||= begin
            return nil unless current_node.type == :send
            Parsing::NodeObjects::SendNode.new(current_node)
          end
        end

        # @return [Parser::AST::Node, nil]
        def current_receiver_node
          current_send&.receiver_node
        end

        # @return [String, nil]
        def index_word
          return nil unless providable?
          @index_word ||= current_send.on_selector?(location) ? current_send.selector_name.slice(0..current_send.offset_in_selector(location)) : ''
        end
      end
    end
  end
end
