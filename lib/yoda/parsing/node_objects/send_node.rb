module Yoda
  module Parsing
    module NodeObjects
      class SendNode
        attr_reader :node

        # @param node [::Parser::AST::Node]
        def initialize(node)
          fail ArgumentError, node unless node.is_a?(::Parser::AST::Node)
          @node = node
        end

        # @return [true, false]
        def on_selector?(location)
          node.location.selector ? selector_range.include?(location) : false
        end

        # @param location [Location]
        # @return [true, false]
        def on_dot?(location)
          node.location.dot ? dot_range.include?(location) : false
        end

        # @param location [Location]
        # @return [true, false]
        def on_parameter?(location)
          parameter_range.include?(location)
        end

        # @return [Range]
        def parameter_range
          @parameter_range ||=
            Range.new(
              Location.of_ast_location(node.location.selector.end),
              Location.of_ast_location(node.location.expression.end).move(row: 0, column: -1),
            )
        end

        # @return [Range]
        def selector_range
          @selector_range ||= Range.of_ast_location(node.location.selector)
        end

        # @return [Range, nil]
        def dot_range
          @dot_range ||= node.location.dot && Range.of_ast_location(node.location.dot)
        end

        # @return [Location, nil]
        def next_location_to_dot
          node.location.dot && Range.of_ast_location(node.location.dot).end_location
        end

        # @return [Parser::AST::Node, nil]
        def receiver_node
          node && node.children[0]
        end

        # @return [String]
        def selector_name
          node.children[1].to_s
        end

        # @param location [Location]
        # @return Integer
        def offset_in_selector(location)
          location.offset_from_begin(node.location.selector)[:column]
        end
      end
    end
  end
end
