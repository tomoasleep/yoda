require 'rbs'

module Yoda
  module Model
    # Environment can resolve constants from type expressions.
    class Environment
      require 'yoda/model/environment/accessor_interface'
      require 'yoda/model/environment/instance_accessor'
      require 'yoda/model/environment/namespace_members'
      require 'yoda/model/environment/singleton_accessor'
      require 'yoda/model/environment/value_factory'
      require 'yoda/model/environment/with_cache'


      # @param project [Store::Project]
      def self.from_project(project)
        new(registry: project.registry, rbs_environment: project.rbs_environment)
      end

      # @param registry [Store::Registry::ProjectRegistry, nil]
      # @param rbs_environment [RBS::Environment, nil]
      # @return [Environment]
      def self.build(registry: nil, rbs_environment: nil)
        # TODO: Allow to make registry parameter empty
        registry ||= Yoda::Store::Registry.new(Yoda::Store::Adapters::MemoryAdapter.new)
        rbs_environment ||= RBS::Environment.new
        new(registry: registry, rbs_environment: rbs_environment)
      end

      # @return [Store::Registry::ProjectRegistry]
      attr_reader :registry

      # @return [RBS::Environment]
      attr_reader :rbs_environment

      # @param registry [Store::Registry::ProjectRegistry]
      # @param rbs_environment [RBS::Environment]
      def initialize(registry:, rbs_environment:)
        @registry = registry
        @rbs_environment = rbs_environment
      end

      # @param rbs_type [RBS::Types::Bases::Base, RBS::Types::Variable, RBS::Types::ClassSingleton, RBS::Types::Interface, RBS::Types::ClassInstance, RBS::Types::Alias, RBS::Types::Tuple, RBS::Types::Record, RBS::Types::Optional, RBS::Types::Union, RBS::Types::Intersection, RBS::Types::Function, RBS::Types::Block, RBS::Types::Proc, RBS::Types::Literal]
      # @return [Values::Base, nil]
      def resolve_value_by_rbs_type(rbs_type)
        ValueFactory.from_environment(self).resolve_value_by_rbs_type(rbs_type)
      end

      # @param type_expression [TypeExpression]
      # @return [RBS::Types::Bases::Base, RBS::Types::Variable, RBS::Types::ClassSingleton, RBS::Types::Interface, RBS::Types::ClassInstance, RBS::Types::Alias, RBS::Types::Tuple, RBS::Types::Record, RBS::Types::Optional, RBS::Types::Union, RBS::Types::Intersection, RBS::Types::Function, RBS::Types::Block, RBS::Types::Proc, RBS::Types::Literal]
      def resolve_rbs_type(type_expression)
        type_expression.to_rbs_type(self)
      end

      # Return {RBS::TypeName} for the instance of the given path.
      # @param path [ScopedPath, Path, String]
      # @return [RBS::TypeName]
      def resolve_rbs_type_name(path)
        scoped_path = ScopedPath.build(path)
        # TODO: ask both registry in lexical priority
        object = resolve_constant(scoped_path)
        return TypeName(object.path).absolute! if object
        rbs_type_name_resolver.resolve(TypeName(scoped_path.path.to_s), context: scoped_path.lexical_context.to_rbs_context)
      end

      # @param key [String, Path, ScopedPath]
      # @return [Store::Objects::Base, nil]
      def resolve_constant(key)
        Store::Query::FindConstant.new(registry).find(key)&.with_connection(registry: registry)
      end

      # @param key [String, Path, ScopedPath]
      # @return [Store::Objects::MetaClassObject, nil]
      def resolve_singleton_class(key)
        Store::Query::FindMetaClass.new(registry).find(key)&.with_connection(registry: registry)
      end

      # @param type_name [RBS::TypeName]
      # @param return [RBS::AST::Declarations::Class, nil]
      def resolve_rbs_class_decl(type_name)
        rbs_environment.class_decls[type_name]
      end

      # @param type_name [RBS::TypeName]
      # @param return [RBS::AST::Declarations::Interface, nil]
      def resolve_rbs_interface_decl(type_name)
        rbs_environment.interface_decls[type_name]&.decl
      end

      # @param type_name [RBS::TypeName]
      # @param return [RBS::AST::Declarations::Constant, nil]
      def resolve_rbs_constant_decl(type_name)
        environment.rbs_environment.constant_decls[type_name]&.decl
      end

      private

      # @param scoped_path [ScopedPath]
      def resolve_rbs_decl(scoped_path)
        type_name = resolve_type_name(scoped_path)
      end

      def rbs_type_name_resolver
        @rbs_type_name_resolver ||= RBS::TypeNameResolver.from_env(rbs_environment)
      end

    end
  end
end
