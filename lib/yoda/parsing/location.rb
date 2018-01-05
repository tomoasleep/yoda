module Yoda
  module Parsing
    class Location
      attr_reader :row, :column
      # @param row    [Integer]
      # @param column [Integer]
      def initialize(row:, column:)
        @row = row
        @column = column
      end

      def index_of(source)
        (source.split("\n").slice(0, row - 1) || []).map(&:length).reduce(0, &:+) + column
      end

      # @param location [Parser::Source::Map]
      def included?(location)
        return false unless location.expression
        after_begin(location) && before_last(location)
      end

      # @param location [Parser::Source::Map]
      def after_begin(location)
        return false unless location.expression
        (location.line == row && location.column <= column) || location.line < row
      end

      # @param location [Parser::Source::Map]
      def before_last(location)
        return false unless location.expression
        (location.last_line == row && column <= location.last_column ) || row < location.last_line
      end
    end
  end
end
