module Yoda
  module Typing
    module Traces
      # Store evaluation result for each ast node.
      class Normal < Base
        attr_reader :context, :type

        # @param context [Context]
        # @param type    [Model::Types::Base]
        def initialize(context, type)
          fail ArgumentError, type unless type.is_a?(Model::Types::Base)
          @context = context
          @type = type
        end

        def values
          type.resolve(context.registry)
        end
      end
    end
  end
end
