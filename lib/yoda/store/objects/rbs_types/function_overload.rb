require 'yoda/store/objects/connected_delegation'

module Yoda
  module Store
    module Objects
      module RbsTypes
        class FunctionOverload
          include Serializable

          # @return [MethodTypeContainer]
          attr_reader :type

          # @return [RbsTypes::TypeParam]
          attr_reader :type_params

          # @param type [MethodTypeContainer, String]
          # @param type_params [RbsTypes::TypeParam]
          def initialize(
            type:,
            type_params:
          )
            @type = MethodTypeContainer.of(type)
            @type_params = type_params.map(&RbsTypes::TypeParam.method(:build))
          end

          # @return [Hash]
          def to_h
            {
              type: type.to_h,
              type_params: type_params.map(&:to_h),
            }
          end

          # @return [Model::FunctionSignatures::ParameterList]
          def to_parameter_list
            type.to_parameter_list
          end
        end
      end
    end
  end
end
