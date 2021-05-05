module Yoda
  module Model
    module TypeExpressions
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

        # @param paths [Array<Path>]
        # @return [self]
        def change_root(paths)
          self
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          [Store::Query::FindConstant.new(registry).find(value_class)].compact
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

        # @param env [Environment]
        def to_rbs_type(env)
          case value_class
          when '::TrueClass'
            RBS::Types::Literal.new(literal: true, location: nil)
          when '::FalseClass'
            RBS::Types::Literal.new(literal: false, location: nil)
          when '::NilClass'
            RBS::Types::Bases::Nil.new(location: nil)
          when '::Numeric'
            RBS::Types::Literal.new(literal: value.to_i, location: nil)
          else
            RBS::Types::Literal.new(literal: value, location: nil)
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
