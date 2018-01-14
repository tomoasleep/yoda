module Yoda
  module Parsing
    module NodeObjects
      class ConstNode
        attr_reader :node

        # @param node [::AST::Node]
        def initialize(node)
          fail ArgumentError, node unless node.is_a?(::AST::Node) && node.type == :const
          @node = node
        end

        # @param base [String, nil]
        # @return [String]
        def to_s(base = nil)
          fail ArgumentError, base unless !base || base.is_a?(String)
          paths = []
          looking_node = node
          while true
            return (base ? base + '::' : '') + paths.join('::') unless looking_node
            return '::' + paths.join('::') if looking_node.type == :cbase
            paths.unshift(looking_node.children[1])
            looking_node = looking_node.children[0]
          end
        end
      end
    end
  end
end
