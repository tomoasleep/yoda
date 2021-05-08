module Yoda
  module Model
    module Values
      # @abstract
      class Base
        # @abstract
        # @return [Array<Store::Objects::Base>]
        def referred_objects
          fail NotImplementedError
        end

        # @abstract
        # @param name [String, Symbol]
        # @return [Enumerator<Functions::Wrapper>]
        def select_method(name)
          fail NotImplementedError
        end

        # @abstract
        # @param name [String, Symbol]
        # @return [RBS::Types::t]
        def select_constant_type(name)
          fail NotImplementedError
        end

        # @abstract
        # @param name [String, Symbol]
        # @return [Array<Symbol>]
        def select_constant_paths(name)
          fail NotImplementedError
        end

        # @abstract
        # @return [Base]
        def singleton_class_value
          fail NotImplementedError
        end

        # @abstract
        # @return [Base]
        def instance_value
          fail NotImplementedError
        end
      end
    end
  end
end
