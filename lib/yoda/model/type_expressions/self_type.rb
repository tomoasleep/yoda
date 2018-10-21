module Yoda
  module Model
    module TypeExpressions
      class SelfType < Base
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

        # @return [String]
        def to_s
          value
        end
      end
    end
  end
end
