require 'yoda/model/environment/accessor_interface'
require 'yoda/model/environment/with_cache'

module Yoda
  module Model
    class Environment
      class InstanceAccessor
        include AccessorInterface
        include WithCache

        # @return [Environment]
        attr_reader :environment

        # @return [String, Path]
        attr_reader :path

        # @return [RBS::Types::t]
        attr_reader :type_args

        # @param environment [Environment]
        # @param path [String, Path]
        # @param type_args [Array<RBS::Types::t>]
        def initialize(environment:, path:, type_args:)
          @environment = environment
          @path = path
          @type_args = type_args
        end

        # @return [NamespaceMembers]
        def members
          @members ||= NamespaceMembers.new(accessor: self, environment: environment)
        end

        # @return [Store::Objects::NamespaceObject::Connected, nil]
        def class_object
          with_cache(:class_object) do
            environment.resolve_constant(path)&.with_connection(registry: environment.registry)
          end
        end

        # @return [Store::Objects::NamespaceObject::Connected, nil]
        def self_object
          with_cache(:self_object) do
            if class_object&.kind == :meta_class
              class_object.instance
            else
              nil
            end
          end
        end

        # @return [nil]
        def instance_accessor
          nil
        end

        # @return [SingletonAccessor]
        def singleton_accessor
          SingletonAccessor.new(self)
        end

        # @return [RBS::Definition, nil]
        def rbs_definition
          with_cache(:rbs_definition) do
            if rbs_class_decl
              builder = RBS::DefinitionBuilder.new(env: environment.rbs_environment)
              builder.build_instance(type_name).sub(substitution)
            elsif rbs_interface_decl
              builder = RBS::DefinitionBuilder.new(env: environment.rbs_environment)
              builder.build_interface(type_name).sub(substitution)
            else
              nil
            end
          end
        end

        # @param return [RBS::AST::Declarations::Class, nil]
        def rbs_class_decl
          with_cache(:rbs_class_decl) do
            environment.resolve_rbs_class_decl(type_name)
          end
        end

        # @param return [RBS::AST::Declarations::Interface, nil]
        def rbs_interface_decl
          with_cache(:rbs_interface_decl) do
            environment.resolve_rbs_interface_decl(type_name)
          end
        end

        # @return [RBS::TypeName]
        def type_name
          @type_name ||= TypeName(path.to_s)
        end

        def rbs_definition_builder
          @rbs_definition_builder ||= RBS::DefinitionBuilder.new(env: environment.rbs_environment)
        end

        private

        # @return [RBS::Substitution, nil]
        def substitution
          with_cache(:substitution) do
            decl = rbs_class_decl || rbs_interface_decl

            if decl
              length = decl.type_params.length
              types = length.times.map { |i| type_args[i] || RBS::Types::Bases::Any.new(location: nil) }
              RBS::Substitution.build(
                decl.type_params.map(&:name),
                types,
              )
            end
          end
        end
      end
    end
  end
end
