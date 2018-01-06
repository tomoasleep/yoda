module Yoda
  module Store
    module Types
      class KeyValueType < Base
        attr_reader :name, :key_type, :value_type

        # @param name [String, Path]
        # @param key_type [Base]
        # @param value_type [Base]
        def initialize(name, key_type, value_type)
          @name = name
          @key_type = key_type
          @value_type = value_type
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(KeyValueType) &&
          name == another.name &&
          key_type == another.key_type
          value_type == another.value_type
        end

        def hash
          [self.class.name, name, key_type, value_type].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [KeyValueType]
        def change_root(namespace)
          self.class.new(Path.new(namespace, name), key_type.change_root(namespace), value_type.change_root(namespace))
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          [registry.find(name)]
        end
      end
    end
  end
end
