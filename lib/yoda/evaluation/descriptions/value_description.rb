module Yoda
  module Evaluation
    module Descriptions
      class ValueDescription < Base
        attr_reader :value
        # @param value [Store::Values::Base]
        def initialize(value)
          @value = value
        end

        # @return [String]
        def title
          value.path.to_s
        end

        # @return [String]
        def sort_text
          value.name.to_s
        end

        def to_markdown
          <<~EOS
          **#{title}**

          #{value.docstring}
          EOS
        end
      end
    end
  end
end
