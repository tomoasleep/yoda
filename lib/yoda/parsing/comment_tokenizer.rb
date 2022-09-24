require 'parslet'

module Yoda
  module Parsing
    # Tokenize tag parts in the given comment text.
    class CommentTokenizer
      # @return [Array<Sequence, String>]
      def parse(str)
        Generator.new.apply(Tokenizer.new.parse(str))
      end

      class Tokenizer < Parslet::Parser
        rule(:space) { match('[\s&&[^\n]]').repeat(1) }
        rule(:space?) { space.maybe }
        rule(:newline) { match('\n') }

        rule(:comment_begin) { str('#') }
        rule(:tag) { str('@') >> (str('!').maybe >> match('[a-zA-Z0-9_-]').repeat) }

        rule(:name) { (sign.absent? >> match['[:graph:]']).repeat(1) }
        rule(:sign) { match['\[\]<>,{}\(\)'] }

        rule(:comment_token) { sign | name }

        rule(:tagline) { space? >> comment_begin.maybe >> space? >> tag.maybe.as(:tag) >> space? >> (comment_token.as(:token) >> space?).repeat.as(:tokens) }
        rule(:textline) { space? >> comment_begin.maybe >> space? >> match('[^\n]*').as(:text) }
        rule(:base) { (((tagline | textline) >> newline).repeat >> (tagline | textline).maybe).as(:lines) }

        root :base
      end

      class Generator < Parslet::Transform
        rule(token: simple(:token)) { token }
        rule(tag: simple(:tag), tokens: sequence(:tokens)) { Sequence.new(tag: tag, tokens: tokens) }
        rule(tag: simple(:tag), tokens: simple(:token)) { Sequence.new(tag: tag, tokens: [token]) }
        rule(text: simple(:text)) { Text.new(text) }
        rule(lines: sequence(:lines)) { lines }
        rule(lines: simple(:lines)) { [lines] }
      end

      class Sequence
        # @return [Parslet::Slice, nil]
        attr_reader :tag

        # @param tag [Parslet::Slice, nil]
        # @param tokens [Array<Parslet::Slice>]
        def initialize(tag: nil, tokens: [])
          fail ArgumentError, tag if tag && !tag.is_a?(Parslet::Slice)
          fail ArgumentError, tokens unless tokens.all? { |token| token.is_a?(Parslet::Slice) }

          @tag = tag
          @tokens = tokens
        end

        # @return [Array<Parslet::Slice>]
        def all_tokens
          @all_tokens ||= [@tag, *parameter_tokens].compact
        end

        # @return [Array<Parslet::Slice>]
        def parameter_tokens
          @tokens
        end
      end

      class Text
        # @return [Parslet::Slice]
        attr_reader :content

        # @param content [Parslet::Slice]
        def initialize(content)
          @content = content
        end
      end
    end
  end
end
