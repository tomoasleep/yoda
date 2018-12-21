require 'securerandom'

module Yoda
  module Typing
    module Types
      class Var < Base
        def initialize(label = nil, ref = nil)
          @id = SecureRandom.alphanumeric(20)
          @label = label
          @ref = ref
        end

        # @param new_ref [Base]
        def ref=(new_ref)
          return if new_ref == self
          @ref = new_ref
        end

        def reference?
          true
        end

        # @return [Base, nil]
        def ref
          @ref&.ref
        end

        def to_expression
          ref&.to_expression || Store::TypeExpressions::UnknownType.new
        end
      end
    end
  end
end
