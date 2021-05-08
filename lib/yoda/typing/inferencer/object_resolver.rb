module Yoda
  module Typing
    class Inferencer
      # Find object for the given constraints.
      class ObjectResolver
        # @return [Store::Registry]
        attr_reader :registry

        # @return [Types::Generator]
        attr_reader :generator

        # @param registry [Store::Registry]
        # @param generator [Types::Generator]
        def initialize(registry:, generator:)
          @registry = registry
        end

        # @param type [Types::Base]
        # @return [Array<Store::Objects::Base>]
        def call(type)
          case type
          when Types::Any
            []
          when Types::Var
            type.ref ? call(type.ref) : []
          when Types::Instance
            [type.klass]
          when Types::Union
            type.types.map { |type| call(type) }.flatten
          when Types::Generic
            call(type.base)
          when Types::AssociativeArray
            [generator.hash_type]
          when Types::Tuple
            [generator.array_type]
          else
            []
          end
        end

        # @param receiver_value [Model::Values::Base]
        # @param parent [Contexts::Base]
        # @return [Contexts::Base]
        def generate_class_context(instance_type, parent:)
          Contexts::NamespaceContext.new(
            receiver_value: instance_value.singleton_class_value,
            parent: parent,
            registry: registry,
          )
        end

      end
    end
  end
end
