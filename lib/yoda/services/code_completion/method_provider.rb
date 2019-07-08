module Yoda
  module Services
    class CodeCompletion
      class MethodProvider < BaseProvider
        # @return [true, false]
        def providable?
          !!current_send
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

        # @return [Array<FunctionSignatures::Base>]
        def method_candidates
          return [] unless providable?
          @method_candidates ||= receiver_values.flat_map do |receiver|
            Store::Query::FindSignature.new(registry).select(receiver, /\A#{Regexp.escape(index_word)}/, visibility: method_visibility)
          end
        end

        # @return [Array<Symbol>]
        def method_visibility
          if current_send.implicit_receiver?
            %i(public)
          else
            %i(public private protected)
          end
        end

        # @return [Array<Store::Objects::Base>]
        def receiver_values
          @receiver_values ||= evaluator.receiver_candidates(current_send) || []
        end

        # @return [AST::SendNode, nil]
        def current_send
          @current_send ||= current_node&.type == :send ? current_node : nil
        end

        # @return [AST::Node, nil]
        def current_receiver_node
          current_send&.receiver
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
