module Yoda
  module Typing
    module Traces
      # Store evaluation result for each ast node.
      class Send < Base
        # @return [Context]
        attr_reader :context

        # @return [Array<Model::FunctionSignatures::Base>]
        attr_reader :functions

        # @return [Model::TypeExpressions::Base]
        attr_reader :type

        # @param context [Context]
        # @param functions [Array<Model::FunctionSignatures::Base>]
        # @param type [Array<Model::TypeExpressions::Base>]
        def initialize(context, functions, type)
          @context = context
          @functions = functions
          @type = type
        end
      end
    end
  end
end
