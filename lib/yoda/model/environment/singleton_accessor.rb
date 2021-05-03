require 'forwardable'

require 'yoda/model/environment/accessor_interface'
require 'yoda/model/environment/with_cache'

module Yoda
  module Model
    class Environment
      class SingletonAccessor
        extend Forwardable
        include AccessorInterface
        include WithCache

        # @return [InstanceAccessor, SingletonAccessor]
        attr_reader :instance_accessor

        delegate [:rbs_definition_builder, :environment] => :instance_accessor

        # @param instance_accessor [InstanceAccessor, SingletonAccessor]
        def initialize(instance_accessor)
          @instance_accessor = instance_accessor
        end

        # @return [NamespaceMembers]
        def members
          @members ||= NamespaceMembers.new(accessor: self, environment: environment)
        end

        # @return [SingletonAccessor]
        def singleton_accessor
          SingletonAccessor.new(self)
        end

        # @return [RBS::Definition, nil]
        def rbs_definition
          with_cache(:rbs_definition) do
            if instance_accessor.rbs_definition
              if instance_accessor.rbs_definition.self_type.is_a?(RBS::Types::ClassInstance)
                rbs_definition_builder.build_singleton(instance_accessor.rbs_definition.type_name)
              else
                # Interface or Singleton
                nil
              end
            else
              nil
            end
          end
        end

        # @return [Store::Objects::MetaClassObject::Connected, nil]
        def class_object
          with_cache(:object) do
            instance_accessor.class_object&.meta_class
          end
        end

        # @return [Store::Objects::MetaClassObject::Connected, nil]
        def self_object
          with_cache(:object) do
            instance_accessor.class_object
          end
        end
      end
    end
  end
end
