module Yoda
  module Model
    module Values
      class IntersectionValue < Base
        # @return [Environment::AccessorInterface]
        attr_reader :values

        # @param values [Array<Value>]
        def initialize(*values)
          @values = values
        end

        def referred_objects
          values.flat_map(&:referred_objects)
        end

        # @param name [String, Symbol]
        # @return [Array<FunctionSignatures::Base>]
        def select_method(name, **kwargs)
          values.flat_map { |value| select_method(name, **kwargs) }
        end

        # @param name [String, Symbol]
        # @return [RBS::Types::t]
        def select_constant_type(name, **kwargs)
          types = values.flat_map { |value| select_constant_type(name, **kwargs) }
          RBS::Types::Intersection.new(types: types, location: nil)
        end

        # @param name [String, Symbol]
        # @return [Array<String>]
        def select_constant_paths(name, **kwargs)
          values.flat_map { |value| select_constant_type(name, **kwargs) }.uniq
        end

        # @return [UnionValue]
        def singleton_class_value
          IntersectionValue.new(*values.map(&:singleton_class_value))
        end

        # @return [UnionValue]
        def instance_value
          IntersectionValue.new(*values.map(&:instance_value))
        end
      end
    end
  end
end
