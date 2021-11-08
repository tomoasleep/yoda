require 'yoda/typing/inferencer/tracer/masked_map'

module Yoda
  module Typing
    class Inferencer
      class Tracer
        class TypeTracer
          # @pram generator [Types::Generator]
          def initialize(generator:)
            @node_to_type = {}
            @generator = generator
          end

          # @param node [AST::Node]
          # @param type [Types::Base]
          def bind(node, type)
            @node_to_type[node.identifier] = type
          end

          # @param node [AST::Node]
          # @return [Types::Type]
          def type(node)
            resolve(node) || @generator.unknown_type(reason: "not traced")
          end

          # @param node [AST::Node]
          # @return [Array<Store::Objects::Base>]
          def objects(node)
            type(node).value.referred_objects
          end

          private

          # @param node [AST::Node]
          # @return [Types::Base, nil]
          def resolve(node)
            @node_to_type[node.identifier]
          end
        end
      end
    end
  end
end
