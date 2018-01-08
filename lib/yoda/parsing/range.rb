module Yoda
  module Parsing
    class Range
      attr_reader :begin_location, :end_location
      # @param begin_location [Integer]
      # @param end_location   [Integer]
      def initialize(begin_location, end_location)
        @begin_location = begin_location
        @end_location = end_location
      end

      # @param ast_location [Parser::Source::Map]
      # @return [Location, nil]
      def self.of_ast_location(ast_location)
        return nil unless Location.valid_location?(ast_location)
        new(
          Location.new(row: ast_location.line, column: ast_location.column),
          Location.new(row: ast_location.last_line, column: ast_location.last_column),
        )
      end

      # @return [{Symbol => { Symbol => Integer } }]
      def to_language_server_protocol_range
        { start: begin_location.to_language_server_protocol_range, end: end_location.to_language_server_protocol_range }
      end
    end
  end
end
