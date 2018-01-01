module Yoda
  module Store
    module Types
      class ConstantType < Base
        attr_reader :value

        VALUE_REGEXP = /\A[0-9a-z]/

        # @param value [String, Path]
        def initialize(value)
          @value = value
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(ConstantType) &&
          value == another.value
        end

        def hash
          [self.class.name, value].hash
        end

        def is_value?
          VALUE_REGEXP.match?(value)
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [ConstantType]
        def change_root(namespace)
          self.class.new(is_value? ? value : Path.new(namespace, value))
        end
      end
    end
  end
end
