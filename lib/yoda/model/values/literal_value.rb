require 'forwardable'

module Yoda
  module Model
    module Values
      class LiteralValue
        extend Forwardable

        delegate [:referred_objects, :select_method, :select_constant_type, :select_constant_paths, :singleton_class_value, :instance_value] => :value

        # @return [Base]
        attr_reader :value

        # @param value [Base]
        # @param literal [Object]
        def initialize(value:, literal:)
          @value = value
          @literal = literal
        end
      end
    end
  end
end
