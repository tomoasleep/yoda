module Yoda
  module Store
    module Types
      class ValueType < Base
        attr_reader :value

        VALUE_REGEXP = /\A[0-9a-z]/

        # @param value [String]
        def initialize(value)
          @value = value
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(ValueType) &&
          value == another.value
        end

        def hash
          [self.class.name, value].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [ConstantType]
        def change_root(namespace)
          self.class.new(value)
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          [registry.find(value_class)].compact
        end

        # @param registry [Registry]
        # @return [Array<Values::Base>]
        def instanciate(registry)
          resolve(registry).map { |el| Values::InstanceValue.new(registry, el) }
        end

        def value_class
          case value
          when 'true'
            '::TrueClass'
          when 'false'
            '::FalseClass'
          when 'nil'
            '::NilClass'
          when /\A\d+\Z/
            '::Numeric'
          else
            nil
          end
        end

        # @return [String]
        def to_s
          value
        end
      end
    end
  end
end
