module Yoda
  module Typing
    module Traces
      # Store evaluation result for each ast node.
      class Send < Base
        attr_reader :context, :functions
        # @param context [Context]
        # @param methods [Array<Store::Function>]
        def initialize(context, functions)
          @context = context
          @functions = functions
        end

        def type
          @type ||= Store::Types::UnionType.new(functions.map(&:return_type))
        end

        def values
          @values ||= context.instanciate(type)
        end
      end
    end
  end
end
