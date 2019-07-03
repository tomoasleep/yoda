require 'parser/current'

module Yoda
  module Parsing
    class Parser
      # @param string [String]
      # @return [AST::Vnode]
      def parse(string)
        AST.wrap(::Parser::CurrentRuby.parse(string))
      end

      # @param string [String]
      # @return [(AST::Vnode, Array<::Parser::Source::Comment>)]
      def parse_with_comments(string)
        node, comments = ::Parser::CurrentRuby.parse_with_comments(string)
        [AST.wrap(node), comments]
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
