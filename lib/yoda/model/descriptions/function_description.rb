module Yoda
  module Model
    module Descriptions
      class FunctionDescription < Base
        # @return [FunctionSignatures::Base]
        attr_reader :function

        # @param function [FunctionSignatures::Base]
        def initialize(function)
          fail ArgumentError, function unless function.is_a?(FunctionSignatures::Base)
          @function = function
        end

        def title
          "#{function.namespace_path}#{function.sep}#{function.to_s}"
        end

        def label
          signature
        end

        def signature
          "#{function.to_s}"
        end

        def sort_text
          function.name.to_s
        end

        def parameter_names
          function.parameters.parameter_names
        end

        def to_markdown
          <<~EOS
          **#{title}**

          #{function.document}
          EOS
        end
      end
    end
  end
end
