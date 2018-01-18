module Yoda
  module Evaluation
    module Descriptions
      class ValueDescription < Base
        attr_reader :value
        # @param value [Store::Values::Base]
        def initialize(value)
          @value = value
        end

        def to_markdown
          <<~EOS
          **#{value.path}**
          
          #{value.docstring}
          EOS
        end
      end
    end
  end
end
