require 'forwardable'
require 'yoda/typing/types/rbs_type_wrapper_interface'

module Yoda
  module Typing
    module Types
      class InstanceType
        extend Forwardable
        include RbsTypeWrapperInterface

        # @return [Model::Environment]
        delegate environment: :singleton_type

        # @return [RbsTypeWrapperInterface]
        attr_reader :singleton_type

        # @param singleton_type [Type, SingletonType]
        def initialize(singleton_type)
          @singleton_type = singleton_type
        end

        # @return [RBS::Types::t]
        def rbs_type
          @rbs_type ||= make_instance(singleton_type.rbs_type)
        end

        # @return [Model::Values::Base]
        def value
          @value ||= singleton_type.value.instance_value
        end

        # @return [InstanceType]
        def instance_type
          InstanceType.new(self)
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

        # @param pp [PP]
        def pretty_print(pp)
          pp.object_group(self) do
            pp.breakable
            pp.text "@rbs_type="
            pp.pp rbs_type.to_s
          end
        end

        private

        # @param rbs_type [RBS::Types::t]
        # @return [RBS::Types::t]
        def make_instance(rbs_type)
          if rbs_type.is_a?(RBS::Types::ClassSingleton)
            RBS::Types::ClassInstance.new(name: rbs_type.name, args: [], location: nil)
          elsif rbs_type.respond_to?(:type_map)
            rbs_type.type_map(&method(:make_instance))
          else
            rbs_type
          end
        end
      end
    end
  end
end

