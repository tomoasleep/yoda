module Yoda
  module Commands
    # Provide parsing methods of positon representation with the format `path/to/file:line_num:character_num`
    module FileCursorParsable
      private

      # Returns a cursor literal to parse.
      # @abstract
      # @return [String]
      def filename_with_position
        fail NotImplementedError
      end

      # @return [String, nil] represents the filename part.
      def filename
        @filename ||= filename_with_position.split(':').first
      end

      # Parse location part of cursor literal and returns the parsed location.
      # @return [Parsing::Location]
      def position
        @position ||= begin
          row, column = filename_with_position.split(':').slice(1..2)
          Parsing::Location.new(row: row.to_i, column: column.to_i)
        end
      end
    end
  end
end
