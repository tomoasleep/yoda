module Yoda
  module Model
    module Values
      class EmptyValue < Base
        # @param name [String, Symbol]
        # @return [Array<Functions::Base>]
        def select_method(name, **kwargs)
          []
        end

        def referred_objects
          []
        end

        # @param name [String, Symbol]
        # @return [RBS::Types::t]
        def select_constant_type(name, **kwargs)
          RBS::Types::Bases::Any.new(location: nil)
        end

        # @param name [String, Symbol]
        # @return [Array<String>]
        def select_constant_paths(name, **kwargs)
          []
        end

        # @return [EmptyValue]
        def singleton_class_value
          self
        end

        # @return [EmptyValue]
        def instance_value
          self
        end
      end
    end
  end
end
