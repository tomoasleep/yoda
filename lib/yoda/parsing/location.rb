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

      # @param line    [Integer]
      # @param character [Integer]
      # @return [Location]
      def self.of_language_server_protocol_position(line:, character:)
        new(row: row + 1, column: column)
      end

      # @param location [Parser::Source::Range, Parser::Source::Map, Object]
      def self.valid_location?(location)
        return false if !location.is_a?(::Parser::Source::Range) && !location.is_a?(::Parser::Source::Map)
        return false if location.is_a?(::Parser::Source::Map) && !location.expression
        true
      end

      # @param location [Parser::Source::Range, Parser::Source::Map]
      def index_of(source)
        (source.split("\n").slice(0, row - 1) || []).map(&:length).reduce(0, &:+) + column
      end

      # @param location [Parser::Source::Range, Parser::Source::Map]
      def included?(location)
        return false unless self.class.valid_location?(location)
        after_begin(location) && before_last(location)
      end

      # @param location [Parser::Source::Range, Parser::Source::Map]
      def after_begin(location)
        return false unless self.class.valid_location?(location)
        (location.line == row && location.column <= column) || location.line < row
      end

      # @param location [Parser::Source::Range, Parser::Source::Map]
      def before_last(location)
        return false unless self.class.valid_location?(location)
        (location.last_line == row && column <= location.last_column ) || row < location.last_line
      end

      # @param location [Parser::Source::Range, Parser::Source::Map]
      # @return [{Symbol => Numerical}]
      def offset_from_begin(location)
        fail ArgumentError, location unless self.class.valid_location?(location)
        { line: row - location.line, column: column - location.column }
      end

      # @return [{Symbol => Integer}]
      def to_language_server_protocol_range
        { line: row - 1, character: column }
      end
    end
  end
end
