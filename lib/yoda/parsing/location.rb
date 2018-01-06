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

      # @param location [Parser::Source::Range, Parser::Source::Map]
      def included?(location)
        return false unless valid_location?(location)
        after_begin(location) && before_last(location)
      end

      # @param location [Parser::Source::Range, Parser::Source::Map]
      def after_begin(location)
        return false unless valid_location?(location)
        (location.line == row && location.column <= column) || location.line < row
      end

      # @param location [Parser::Source::Range, Parser::Source::Map]
      def before_last(location)
        return false unless valid_location?(location)
        (location.last_line == row && column <= location.last_column ) || row < location.last_line
      end

      # @param location [Parser::Source::Range, Parser::Source::Map]
      # @return [{Symbol => Numerical}]
      def offset_from_begin(location)
        fail ArgumentError, location unless valid_location?(location)
        { line: row - location.line, column: column - location.column }
      end

      def valid_location?(location)
        return false if !location.is_a?(::Parser::Source::Range) && !location.is_a?(::Parser::Source::Map)
        return false if location.is_a?(::Parser::Source::Map) && !location.expression
        true
      end
    end
  end
end
