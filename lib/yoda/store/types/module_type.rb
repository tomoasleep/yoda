module Yoda
  module Store
    module Types
      class ModuleType < Base
        attr_reader :value

        VALUE_REGEXP = /\A[0-9a-z]/

        # @param value [String, Path]
        def initialize(value)
          @value = value
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(ModuleType) &&
          value == another.value
        end

        def hash
          [self.class.name, value].hash
        end

        def is_value?
          value.is_a?(String) && VALUE_REGEXP.match?(value)
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [ConstantType]
        def change_root(namespace)
          self.class.new(is_value? ? value : Path.new(namespace, value))
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          [registry.find(value)].compact
        end

        # @param registry [Registry]
        # @return [Array<Values::Base>]
        def instanciate(registry)
          resolve(registry).map { |el| Values::ModuleValue.new(registry, el) }
        end
      end
    end
  end
end
