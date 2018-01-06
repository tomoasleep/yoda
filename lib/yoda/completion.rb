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
  end
end
