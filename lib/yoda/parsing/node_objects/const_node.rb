module Yoda
  module Parsing
    module NodeObjects
      class ConstNode
        # @param node [AST::Node]
        attr_reader :node

        # @param node [AST::Node]
        def initialize(node)
          fail ArgumentError, node unless node.is_a?(AST::Node) && node.type == :const
          @node = node
        end

        # @return [ConstNode, nil]
        def parent_const
          node.children.first && node.children.first.type == :const ? ConstNode.new(node.children.first) : nil
        end

        # @return [true, false]
        def absolute?
          node.children.first == :cbase
        end

        # @param location [Location]
        # @return [true, false]
        def just_after_separator?(location)
          return false unless node.location.double_colon
          location == Location.of_ast_location(node.location.double_colon.end)
        end

        # @return [Model::Path]
        def to_path
          Model::Path.new(to_s)
        end

        # @param base [String, Symbol, nil]
        # @return [String]
        def to_s(base = nil)
          fail ArgumentError, base unless !base || base.is_a?(String) || base.is_a?(Symbol)
          paths = []
          looking_node = node
          while true
            return (base ? base.to_s + '::' : '') + paths.join('::') unless looking_node
            return '::' + paths.join('::') if looking_node.type == :cbase
            paths.unshift(looking_node.children[1])
            looking_node = looking_node.children[0]
          end
        end
      end
    end
  end
end
