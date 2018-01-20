require 'parser/current'

module Yoda
  module Parsing
    class Parser
      # @param string [String]
      # @return [::Parser::AST::Node]
      def parse(string)
        ::Parser::CurrentRuby.parse(string)
      end

      # @param string [String]
      # @return [(::Parser::AST::Node, Array<::Parser::Source::Comment>)]
      def parse_with_comments(string)
        ::Parser::CurrentRuby.parse_with_comments(string)
      end

      # @param string [String]
      # @return [(::Parser::AST::Node, Array<::Parser::Source::Comment>), nil]
      def parse_with_comments_if_valid(string)
        parse_with_comments(source)
      rescue ::Parser::SyntaxError
        nil
      end
    end
  end
end
