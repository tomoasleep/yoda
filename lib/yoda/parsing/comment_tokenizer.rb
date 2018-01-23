require 'parslet'

module Yoda
  module Parsing
    class CommentTokenizer
      # @return [Sequence]
      def parse(str)
        Generator.new.apply(Tokenizer.new.parse(str))
      end

      class Tokenizer < Parslet::Parser
        rule(:space) { match('\s').repeat(1) }
        rule(:space?) { space.maybe }

        rule(:comment_begin) { str('#') }
        rule(:tag) { str('@') >> (str('!').maybe >> match('[a-zA-Z0-9_-]').repeat) }

        rule(:name) { (sign.absent? >> match['[:graph:]']).repeat(1) }
        rule(:sign) { match['\[\]<>,{}\(\)'] }

        rule(:comment_token) { sign | name }

        rule(:base) { comment_begin.maybe >> space? >> tag.maybe.as(:tag) >> space? >> (comment_token.as(:token) >> space?).repeat.as(:tokens) }
        root :base
      end

      class Generator < Parslet::Transform
        rule(token: simple(:token)) { token }
        rule(tag: simple(:tag), tokens: sequence(:tokens)) { Sequence.new(tag: tag, tokens: tokens) }
        rule(tag: simple(:tag), tokens: simple(:token)) { Sequence.new(tag: tag, tokens: [token]) }
      end

      class Sequence
        # @type Parslet::Slice | nil
        attr_reader :tag

        # @param tag [Parslet::Slice, nil]
        # @param tokens [Array<Parslet::Slice>]
        def initialize(tag: nil, tokens: tokens)
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
    end
  end
end
