module Yoda
  module Evaluation
    module Descriptions
      class FunctionDescription < Base
        attr_reader :function
        # @param function [Store::Function]
        def initialize(function)
          @function = function
        end

        def title
          "#{function.name_with_namespace}#{function.type_signature}"
        end

        def to_markdown
          <<~EOS
          **#{title}**
          
          #{function.docstring}
          EOS
        end
      end
    end
  end
end
