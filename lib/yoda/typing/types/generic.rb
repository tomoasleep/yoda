module Yoda
  module Typing
    module Types
      class Generic < Base
        # @return [Base]
        attr_reader :base

        # @return [Array<Base>]
        attr_reader :type_args

        # @param base [Base]
        # @param type_args [Array<Base>]
        def initialize(base:, type_args:)
          @base = base
          @type_args = type_args
        end

        def to_expression
          base.to_expression
        end
      end
    end
  end
end
