module Yoda
  module Typing
    module Types
      class Resolver
        # @return [Store::Registry]
        attr_reader :registry

        # @return [Integer]
        attr_reader :level

        def initialize(registry:, level:)
          @registry = registry
          @level = level
        end

        # @param type [Base]
        # @return [Store::TypeExpressions::Base]
        def convert_to_expression(type)
          type.to_expression(self)
        end

        def unify(type1, type2)
          type1 = type1.resolve || type1 if type1.reference?
          type2 = type2.resolve || type2 if type2.reference?

          if type1.is_a?(Var)
            type1.ref = type2
          elsif type2.is_a?(Var)
            type2.ref = type1
          else
            # TODO
          end
        end
      end
    end
  end
end
