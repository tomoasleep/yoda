module Yoda
  module Model
    module Descriptions
      class VariableDescription < Base
        # @return [Symbol]
        attr_reader :variable

        # @return [TypeExpressions::Base]
        attr_reader :type

        # @param variable [Symbol]
        # @param type [TypeExpressions::Base]
        def initialize(variable:, type:)
          @variable = variable
          @type = type
        end

        # @return [String]
        def title
          "#{variable}: #{type}"
        end

        # @return [String]
        def sort_text
          variable.to_s
        end

        def to_markdown
          ""
        end

        def markup_content
          {
            language: 'ruby',
            value: "#{variable} # #{type}",
          }
        end
      end
    end
  end
end
