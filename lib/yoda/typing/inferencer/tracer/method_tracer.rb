require 'yoda/typing/inferencer/tracer/masked_map'

module Yoda
  module Typing
    class Inferencer
      class Tracer
        class MethodTracer
          # @param generator [Types::Generator]
          def initialize(generator:)
            @generator = generator
            @node_to_receiver_type = MaskedMap.new
            @node_to_method_candidates = MaskedMap.new
          end

          # @param node [AST::Node]
          # @param method_candidates [Array<Model::FunctionSignatures::Base>]
          def bind_method(node, method_candidates)
            @node_to_method_candidates[node.identifier] = method_candidates
          end

          # @param node [AST::Node]
          # @param receiver_type [Types::Type]
          # @param method_candidates [Array<Model::FunctionSignatures::Base>]
          def bind_send(node, receiver_type, method_candidates)
            @node_to_receiver_type[node.identifier] = receiver_type
            @node_to_method_candidates[node.identifier] = method_candidates
          end

          # @param node [AST::Node]
          # @return [Array<FunctionSignatures::Wrapper>]
          def method_candidates(node)
            @node_to_method_candidates[node.identifier] || []
          end

          # @param node [AST::Node]
          # @return [Types::Type]
          def receiver_type(node)
            @node_to_receiver_type[node.identifier] || @generator.unknown_type(reason: "not traced")
          end
        end
      end
    end
  end
end
