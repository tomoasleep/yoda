module Yoda
  module Model
    module Values
      class UnionValue < Base
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
        # @return [Array<Functions::Base>]
        def select_method(name, **kwargs)
          # Choose methods of shared ancestors
          values.first&.select_method(name, **kwargs) || []
        end

        # @param name [String, Symbol]
        # @return [RBS::Types::t]
        def select_constant_type(name, **kwargs)
          # Choose methods of shared ancestors
          values.first&.select_constant_type(name, **kwargs) || RBS::Types::Bases::Any.new(location: nil)
        end

        # @param name [String, Symbol]
        # @return [Array<String>]
        def select_constant_paths(name, **kwargs)
          # Choose methods of shared ancestors
          values.first&.select_constant_paths(name, **kwargs) || []
        end

        # @return [IntersectionValue]
        def singleton_class_value
          UnionValue.new(*values.map(&:singleton_class_value))
        end

        # @return [IntersectionValue]
        def instance_value
          UnionValue.new(*values.map(&:instance_value))
        end
      end
    end
  end
end
