module Yoda
  module Parsing
    class Location
      include Comparable

      # @todo Make this 0-indexed.
      # @return [Integer] 0-indexed column number.
      attr_reader :row

      # @return [Integer] 0-indexed column number.
      attr_reader :column

      # @param row    [Integer] 1-indexed row number.
      # @param column [Integer] 0-indexed column number.
      def initialize(row:, column:)
        @row = row
        @column = column
      end

      # @param ast_location [Parser::Source::Map, Parser::Source::Range]
      # @return [Location, nil]
      def self.of_ast_location(ast_location)
        return nil unless valid_location?(ast_location)
        Location.new(row: ast_location.line, column: ast_location.column)
      end

      # @param line    [Integer]
      # @param character [Integer]
      # @return [Location]
      def self.of_language_server_protocol_position(line:, character:)
        new(row: line + 1, column: character)
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
      def later_than?(location)
        move(row: 0, column: -1).after_begin(location)
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

      # @param row    [Integer]
      # @param column [Integer]
      # @return [Location]
      def move(row:, column:)
        self.class.new(row: @row + row, column: @column + column)
      end

      # @return [{Symbol => Integer}]
      def to_language_server_protocol_range
        { line: row - 1, character: column }
      end

      def to_s
        "(#{row}, #{column})"
      end

      # @param another [Location]
      # @return [Integer]
      def <=>(another)
        return 0 if row == another.row && column == another.column
        return 1 if (row == another.row && column >= another.column) || row > another.row
        -1
      end
    end
  end
end
