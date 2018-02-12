module Yoda
  module Typing
    module Traces
      # Store evaluation result for each ast node.
      class Send < Base
        attr_reader :context, :functions
        # @param context [Context]
        # @param functions [Array<Store::Objects::MethodObject>]
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
