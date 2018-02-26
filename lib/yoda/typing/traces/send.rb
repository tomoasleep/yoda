module Yoda
  module Typing
    module Traces
      # Store evaluation result for each ast node.
      class Send < Base
        # @return [Context]
        attr_reader :context

        # @return [Array<Model::FunctionSignatures::Base>]
        attr_reader :functions

        # @param context [Context]
        # @param functions [Array<Model::FunctionSignatures::Base>]
        def initialize(context, functions)
          @context = context
          @functions = functions
        end

        def type
          @type ||= Model::Types::UnionType.new(functions.map(&:type).map(&:return_type))
        end
      end
    end
  end
end
