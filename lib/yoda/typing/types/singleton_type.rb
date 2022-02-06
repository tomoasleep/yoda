require 'forwardable'
require 'yoda/typing/types/rbs_type_wrapper_interface'

module Yoda
  module Typing
    module Types
      class SingletonType
        extend Forwardable
        include RbsTypeWrapperInterface

        # @return [Model::Environment]
        delegate environment: :instance_type

        # @return [Type, SingletonType]
        attr_reader :instance_type

        # @param instance_type [Type, SingletonType]
        def initialize(instance_type)
          @instance_type = instance_type
        end

        # @return [RBS::Types::t]
        def rbs_type
          @rbs_type ||= make_singleton(instance_type.rbs_type)
        end

        # @return [Model::Values::Base]
        def value
          @value ||= instance_type.value.singleton_class_value
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
        def make_singleton(rbs_type)
          if rbs_type.is_a?(RBS::Types::ClassInstance)
            RBS::Types::ClassSingleton.new(name: type.name, location: nil)
          elsif rbs_type.respond_to?(:type_map)
            rbs_type.type_map(&method(:make_singleton))
          else
            rbs_type
          end
        end

      end
    end
  end
end

