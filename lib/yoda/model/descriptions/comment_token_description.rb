module Yoda
  module Model
    module Descriptions
      class CommentTokenDescription < Base
        # @return [AST::CommentBlock::Token]
        attr_reader :comment_token

        # @return [TypeExpressions::Base]
        attr_reader :type

        # @param comment_token [AST::CommentBlock::Token]
        # @param type [TypeExpressions::Base]
        def initialize(comment_token, type)
          @comment_token = comment_token
          @type = type
        end

        # @return [String]
        def title
          comment_token.content
        end

        # @return [String]
        def sort_text
          comment_token.content
        end

        # @return [String]
        def to_markdown
          <<~EOS
          **#{title}**

          #{value.document}
          EOS
        end

        def markup_content
          {
            language: 'ruby',
            value: "#{title.gsub("\n", ";")} # #{type}",
          }
        end
      end
    end
  end
end
