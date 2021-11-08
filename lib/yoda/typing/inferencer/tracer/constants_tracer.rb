require 'yoda/typing/inferencer/tracer/masked_map'

module Yoda
  module Typing
    class Inferencer
      class Tracer
        class ConstantsTracer
          def initialize
            @node_to_constants = MaskedMap.new
          end

          # @param node [AST::Node]
          # @param constants [Array<Store::Objects::Base>]
          def bind(node, constants)
            @node_to_constants[node.identifier] = constants
          end

          # @param node [AST::Node]
          # @return [Array<Store::Objects::Base>]
          def constants(node)
            @node_to_constants[node.identifier] || []
          end
        end
      end
    end
  end
end
