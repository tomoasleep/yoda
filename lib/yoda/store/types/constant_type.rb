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
          [registry.find_or_proxy(is_value? ? value_class : value)]
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
      end
    end
  end
end
