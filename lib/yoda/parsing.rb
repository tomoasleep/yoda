module Yoda
  module Parsing
    require 'yoda/parsing/ast_traversable'
    require 'yoda/parsing/comment_tokenizer'
    require 'yoda/parsing/parser'
    require 'yoda/parsing/node_objects'
    require 'yoda/parsing/location'
    require 'yoda/parsing/scopes'
    require 'yoda/parsing/source_cutter'
    require 'yoda/parsing/range'
    require 'yoda/parsing/query'
    require 'yoda/parsing/type_parser'
    require 'yoda/parsing/traverser'

    class << self
      # @see {Parser#parse}
      def parse(*args)
        Parser.new.parse(*args)
      end

      # @see {Parser#parse_with_comments}
      def parse_with_comments(*args)
        Parser.new.parse_with_comments(*args)
      end

      # @see {Parser#parse_with_comments_if_valid}
      def parse_with_comments_if_valid(*args)
        Parser.new.parse_with_comments_if_valid(*args)
      end

      # Fix parse errors of the given source and return the modified source.
      # @param source [String]
      # @param location [Location]
      # @return [String] Modified source to fix parse errors.
      # @raise [SourceCutter::CannotRecoverError]
      def fix_parse_error(source:, location:)
        SourceCutter.new(source, location).error_recovered_source
      end
    end
  end
end
