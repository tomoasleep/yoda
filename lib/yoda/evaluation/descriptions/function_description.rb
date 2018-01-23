module Yoda
  module Evaluation
    module Descriptions
      class FunctionDescription < Base
        attr_reader :function
        # @!sig function Store::Functions::Base

        # @param function [Store::Functions::Base]
        def initialize(function)
          @function = function
        end

        def title
          "#{function.name_signature}#{function.type_signature}"
        end

        def signature
          "#{function.name}#{function.type_signature}"
        end

        def sort_text
          function.name.to_s
        end

        def parameter_names
          function.type.parameters.map(&:first)
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
