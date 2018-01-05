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

      # @param ast [::Parser::AST::Node]
      # @param source [String]
      def initialize(ast, location)
        @ast = ast
        @location = Location.new(row: row, column: column)
      end

      # @return [Array<::Parser::AST::Node>]
      def nodes_to_current_location_from_root
        @nodes_to_current_location ||= calc_nodes_to_current_location(ast, location)
      end

      # @return [::Parser::AST::Node]
      def current_method_node
        nodes_to_current_location_from_root.reverse.find { |node| [:def, :defs].include?(node.type) }
      end

      # @return [Array<::Parser::AST::Node>]
      def current_namespace_nodes
        nodes_to_current_location_from_root.reverse.find_all { |node| [:class, :module, :sclass].include?(node.type) }
      end
    end
  end
end
