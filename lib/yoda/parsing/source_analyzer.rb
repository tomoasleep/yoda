module Yoda
  module Parsing
    class SourceAnalyzer
      include AstTraversable

      # @param source   [String]
      # @param location [Location]
      # @return [SourceAnalyzer]
      def self.from_source(source, location)
        new(Parser.new.parse(source), location)
      end

      attr_reader :ast, :location

      # @param ast      [::Parser::AST::Node]
      # @param location [Location]
      # @param source [String]
      def initialize(ast, location)
        @ast = ast
        @location = location
      end

      # @return [Array<::Parser::AST::Node>]
      def nodes_to_current_location_from_root
        @nodes_to_current_location ||= calc_nodes_to_current_location(ast, location)
      end

      # @return [true, false]
      def on_method?
        !!current_method_node
      end

      # @return [::Parser::AST::Node]
      def current_method_node
        nodes_to_current_location_from_root.reverse.find { |node| [:def, :defs].include?(node.type) }
      end

      # @return [Array<::Parser::AST::Node>]
      def current_namespace_nodes
        nodes_to_current_location_from_root.find_all { |node| [:class, :module, :sclass].include?(node.type) }
      end

      # @return [Namespace]
      def namespace
        @namespace ||= NodeObjects::Namespace.new(self.ast)
      end

      # @return [NodeObjects::Namespace, nil]
      def current_namespace
        @current_namespace ||= namespace.calc_current_location_namespace(location)
      end

      # @return [NodeObjects::MethodDefition, nil]
      def current_method
        @current_method ||= namespace.calc_current_location_method(location)
      end
    end
  end
end
