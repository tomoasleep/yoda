require 'yoda/typing/types/rbs_type_wrapper_interface'

module Yoda
  module Typing
    module Types
      class Type
        include RbsTypeWrapperInterface

        # @return [Model::Environment]
        attr_reader :environment

        # @return [RBS::Types::t]
        attr_reader :rbs_type

        # @param environment [Model::Environment]
        # @param rbs_type [RBS::Types::t]
        def initialize(environment:, rbs_type:)
          @environment = environment
          @rbs_type = rbs_type
        end

        # @return [Model::Values::Base]
        def value
          @value ||= environment.resolve_value_by_rbs_type(rbs_type)
        end

        # @return [InstanceType]
        def instance_type
          InstanceType.new(self)
        end

        # @return [SingletonType]
        def singleton_type
          SingletonType.new(self)
        end

        # @deprecated Use {#value} to access referred objects.
        # @return [Store::Objects::Base]
        def klass
          value.referred_objects.first
        end

        # @return [String]
        def to_s
          rbs_type.to_s
        end
      end
    end
  end
end

