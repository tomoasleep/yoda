module Yoda
  module Store
    module Types
      class ConstantType < Base
        attr_reader :value

        def initialize(value)
          @value = value
        end

        def eql?(another)
          another.is_a?(ConstantType) &&
          value == another.value
        end

        def hash
          [self.class.name, value].hash
        end
      end
    end
  end
end
