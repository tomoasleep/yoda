module Yoda
  module Typing
    module Types
      class Generic < Base
        # @param base [Base]
        # @param type_args [Array<Base>]
        def initialize(base:, type_args:)
          @base = base
          @type_args = type_args
        end

        def to_expression(resolver)
          base.to_expression(resolver)
        end
      end
    end
  end
end
