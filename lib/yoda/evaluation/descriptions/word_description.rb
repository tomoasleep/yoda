module Yoda
  module Evaluation
    module Descriptions
      class WordDescription < Base
        # @return [String]
        attr_reader :word

        # @param function [String]
        def initialize(word)
          @word = word
        end

        # @return [String]
        def title
          word
        end

        # @return [String]
        def sort_text
          word
        end

        # @return [String]
        def to_markdown
          <<~EOS
          word
          EOS
        end
      end
    end
  end
end
