module Yoda
  module Typing
    module Types
      class Literal < Base
        attr_reader :value

        def initialize(value)
          @value = value
        end

        def resolve
          self
        end

        def to_type_string
          value.to_s
        end
      end
    end
  end
end
