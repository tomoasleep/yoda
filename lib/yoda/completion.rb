module Yoda
  class Completion
    attr_reader :source, :row, :column
    # @param source [String]
    # @param row    [Integer]
    # @param column [Integer]
    def initialize(source, row, column)
      @source = source
      @location = Parsing::Location.new(row: row, column: column)
    end

    # @return [Parser::AST::Node]
    def ast
      @ast ||= Parsing::Parser.new.parse(source)
    end

    # @return [Enumerator<YARD::CodeObject::Base>]
    def complete
      index = location.index_of(source)

      parent_nodes = lookup_parent_nodes(current_node)
      find_candidates(parent_nodes, current_node).map
    end

    # @param parent_node  [Parser::AST::Node]
    # @param current_node [Parser::AST::Node]
    # @return [Enumerator<YARD::CodeObject::Base>]
    def find_candidates(parent_node, current_node)
      input = current_node.source

      namespace = parent_node.first&.namespace&.source || :root
      code_object = at(namespace)
      return [] unless code_object
      (code_object&.children || []).select { |obj| obj.name.to_s.start_with?(input) }
    end
  end
end
