module Yoda
  module Store
    module Types
      class KeyValueType < Base
        attr_reader :name, :key_type, :value_type

        def initialize(name, key_type, value_type)
          @name = name
          @key_type = key_type
          @value_type = value_type
        end

        def eql?(another)
          another.is_a?(KeyValueType) &&
          name == another.name &&
          key_type == another.key_type
          value_type == another.value_type
        end

        def hash
          [self.class.name, name, key_type, value_type].hash
        end
      end
    end
  end
end
