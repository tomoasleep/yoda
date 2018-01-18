module Yoda
  module Typing
    module Traces
      # Store evaluation result for each ast node.
      class Normal < Base
        attr_reader :context, :type

        # @param context [Context]
        # @param type    [Store::Types::Base]
        def initialize(context, type)
          fail ArgumentError, type unless type.is_a?(Store::Types::Base)
          @context = context
          @type = type
        end

        def values
          @values ||= context.instanciate(type)
        end
      end
    end
  end
end
