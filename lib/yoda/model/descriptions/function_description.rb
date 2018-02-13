module Yoda
  module Model
    module Descriptions
      class FunctionDescription < Base
        # @type Store::Objects::MethodObject
        attr_reader :function

        # @param function [Store::Objects::MethodObject]
        def initialize(function)
          fail ArgumentError, function unless function.is_a?(Store::Objects::MethodObject)
          @function = function
        end

        def title
          "#{function.namespace_path}#{function.sep}#{function.to_s}"
        end

        def signature
          "#{function.name}#{function.to_s}"
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
