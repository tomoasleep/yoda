require 'parser/current'

module Yoda
  module Parsing
    class Parser
      # @param string [String]
      # @return [AST::Vnode]
      def parse(string)
        parse_with_comments(string).first
      end

      # @param string [String]
      # @return [(AST::Vnode, Array<::Parser::Source::Comment>)]
      def parse_with_comments(string)
        source_buffer = create_source_buffer(source: string)
        node, comments = parser.parse_with_comments(source_buffer)
        comments_by_node = begin
          if ::Parser::Source::Comment.respond_to?(:associate_by_identity)
            ::Parser::Source::Comment.associate_by_identity(node, comments)
          else
            ::Parser::Source::Comment.associate(node, comments)
          end
        end
        [AST.wrap(node, comments_by_node: comments_by_node), comments]
      end

      # @param string [String]
      # @return [(::Parser::AST::Node, Array<::Parser::Source::Comment>), nil]
      def parse_with_comments_if_valid(string)
        parse_with_comments(string)
      rescue ::Parser::SyntaxError
        nil
      end

      # @param source [String]
      # @param recover [Boolean].
      # @return [Array] See {::Parser::Base.tokenize}
      def tokenize(source, recover: false)
        parser.tokenize(create_source_buffer(source: source), recover)
      end

      private

      # @return [::Parser::Base]
      def parser
        # Don't use {::Parser::Base.default_parser} because the generated parser by the method reports errors to stdout.
        @parser ||= ::Parser::CurrentRuby.new.tap do |parser|
          parser.diagnostics.all_errors_are_fatal = true
          parser.diagnostics.ignore_warnings = true
        end
      end

      # @param source [String]
      # @param filename [String, nil]
      # @param line [Integer, nil]
      # @return [::Parser::Source::Buffer]
      def create_source_buffer(source:, filename: "(source)", line: 1)
        source = source.dup.force_encoding(parser.default_encoding)

        ::Parser::Source::Buffer.new(filename, line).tap do |buffer|
          buffer.source = source
        end
      end
    end
  end
end
