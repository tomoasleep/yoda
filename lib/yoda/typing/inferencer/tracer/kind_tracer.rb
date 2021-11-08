require 'yoda/typing/inferencer/tracer/masked_map'

module Yoda
  module Typing
    class Inferencer
      class Tracer
        class KindTracer
          def initialize
            @node_to_kind = {}
          end

          # @param node [AST::Node]
          # @param kind [Symbol, nil]
          def bind(node, kind)
            @node_to_kind[node.identifier] = kind
          end

          # @param node [AST::Node]
          # @return [Symbol, nil]
          def kind(node)
            @node_to_kind[node.identifier]
          end

          alias_method :resolve, :kind
        end
      end
    end
  end
end
