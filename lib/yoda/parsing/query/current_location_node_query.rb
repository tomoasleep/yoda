module Yoda
  module Parsing
    module Query
      class CurrentLocationQuery
        attr_reader :ast, :location

        # @param ast      [::Parser::AST::Node]
        # @param location [Location]
        def initialize(ast, location)
          @ast = ast
          @location = location
        end

        # @return [NodeObjects::Namespace, nil]
        def current_namespace
          @current_namespace ||= namespace.calc_current_location_namespace(location)
        end

        # @return [NodeObjects::MethodDefition, nil]
        def current_method_definition
          @current_method_definition ||= namespace.calc_current_location_method(location)
        end

        private

        # @return [Namespace]
        def namespace
          @namespace ||= NodeObjects::Namespace.new(self.ast)
        end

        # @return [Array<::Parser::AST::Node>]
        def nodes_to_current_location_from_root
          @nodes_to_current_location ||= calc_nodes_to_current_location(ast, location)
        end

        # @param root_node [Array<::Parser::AST::Node>]
        # @param current_location [Parser::Source::Map]
        # @return [Array<::Parser::AST::Node>]
        def calc_nodes_to_current_location(root_node, current_location)
          nodes = []
          node = root_node
          while node && !node.children.empty?
            nodes << node
            node = node.children.find { |n| n.respond_to?(:location) && current_location.included?(n.location) }
          end
          nodes
        end
      end
    end
  end
end
