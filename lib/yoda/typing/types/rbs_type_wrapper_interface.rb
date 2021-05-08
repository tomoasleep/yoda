module Yoda
  module Typing
    module Types
      module RbsTypeWrapperInterface
        # @abstract
        # @return [Model::Environment]
        def environment
          fail NotImplementedError
        end

        # @abstract
        # @return [RBS::Types::t]
        def rbs_type
          fail NotImplementedError
        end

        # @abstract
        # @return [Model::Values::Base]
        def value
          fail NotImplemetedError
        end

        # @abstract
        # @return [Type]
        def instance_type
          fail NotImplemetedError
        end

        # @abstract
        # @return [Type]
        def singleton_type
          fail NotImplemetedError
        end

        # @abstract
        # @return [String]
        def to_s
          fail NotImplemetedError
        end
      end
    end
  end
end

