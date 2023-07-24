require 'rbs'
require 'set'

module Yoda
  module Store
    class RbsImporter
      # @return [Objects::Patch]
      attr_reader :patch

      # @return [String, nil]
      attr_reader :root_path

      # @return [String, nil]
      attr_reader :source_path

      # @return [RBS::Environment]
      attr_reader :environment

      # @param id [String]
      # @param root_path [String, nil]
      # @param source_path [String, nil] if given overwrite the source path of objects.
      # @param environment [RBS::Environment]
      def initialize(id, root_path: nil, source_path: nil, environment:)
        @patch = Objects::Patch.new(id)
        @root_path = root_path
        @source_path = source_path
        @environment = environment
        @registered = Set.new
      end

      # @return [Objects::Patch]
      def import
        environment.declarations.each do |decl|
          Traverser.new(self, namespace: RBS::Namespace.root, context: {}).traverse(decl)
        end
        patch
      end

      class Traverser
        # @return [RbsImporter]
        attr_reader :importer

        # @return [RBS::Namespace]
        attr_reader :namespace

        # @return [{ Symbol => Objects::RbsTypes::TypeParam }}]
        attr_reader :context

        # @type
        #   (
        #     RbsImporter importer,
        #     context: { Symbol => Objects::RbsTypes::TypeParam },
        #     visibility: Symbol,
        #   ) -> void
        def initialize(importer, namespace:, context: {})
          @importer = importer
          @namespace = namespace
          @context = context
        end

        # @type (RBS::AST::Declarations::t declaration) -> (Array[Objects::Base])
        def traverse(declaration)
          new_objects = begin
            case declaration
            when RBS::AST::Declarations::Class
              process_class(declaration)
            when RBS::AST::Declarations::Module
              process_module(declaration)
            when RBS::AST::Declarations::Interface
              # process_interface(declaration)
            when RBS::AST::Declarations::Constant
              process_constant(declaration)
            when RBS::AST::Declarations::Global
              # process_global(declaration)
            when RBS::AST::Declarations::TypeAlias
              # process_alias(declaration)
            when RBS::AST::Declarations::ClassAlias
              # process_alias(declaration)
            when RBS::AST::Declarations::ModuleAlias
              # process_alias(declaration)
            else
              fail ArgumentError, 'Unsupported type code object'
            end
          end

          [new_objects].flatten.compact.each { |new_object| importer.patch.register(new_object) }
        end

        # @type (RBS::AST::Declarations::t declaration, Array[RBS::AST::Members::t] members) -> MembersResult
        def traverse_members(declaration, members)
          instance_methods = []
          singleton_methods = []
          includes = []
          extends = []
          prepends = []

          visibility = :public

          members.each do |member|
            case member
            when RBS::AST::Members::MethodDefinition
              method_name = member.name.to_s

              gen_overloads = ->(path) do
                member.overloads.map do |overload|
                  new_context = declaration.type_params.map.with_index { |type_param, idx| [type_param.name, Objects::RbsTypes::ParameterPosition.new(address: path, index: idx)] }.to_h

                  derive(context: new_context).instance_eval do
                    function_overload = Objects::RbsTypes::FunctionOverload.new(
                      type_params: declaration.type_params,
                      type: convert_method_type(overload.method_type),
                    )

                    Objects::Overload.new(
                      name: method_name,
                      rbs_function_overload: function_overload,
                      parameters: function_overload.to_parameter_list.raw_parameters,
                      document: member.comment&.string || '',
                    )
                  end
                end
              end

              sources = location_to_sources(member.location)

              if %i(instance singleton_instance).include?(member.kind)
                instance_methods.push(
                  Objects::MethodObject.new(
                    path: "#{path_of(declaration)}##{method_name}",
                    overloads: gen_overloads.call("#{path_of(declaration)}##{method_name}"),
                    document: member.comment&.string || '',
                    sources: sources,
                    primary_source: sources.first,
                  )
                )
              end

              if %i(singleton singleton_instance).include?(member.kind)
                singleton_methods.push(
                  Objects::MethodObject.new(
                    path: "#{path_of(declaration)}.#{method_name}",
                    overloads: gen_overloads.call("#{path_of(declaration)}.#{method_name}"),
                    document: member.comment&.string || '',
                    sources: sources,
                    primary_source: sources.first,
                  )
                )
              end
            when RBS::AST::Members::Public
              visibility = :public
            when RBS::AST::Members::Private
              visibility = :private
            when RBS::AST::Members::Include
              includes.push(Objects::RbsTypes::NamespaceAccess.new(name: member.name.to_s, args: member.args.map(&method(:convert_type))))
            when RBS::AST::Members::Extend
              extends.push(Objects::RbsTypes::NamespaceAccess.new(name: member.name.to_s, args: member.args.map(&method(:convert_type))))
            when RBS::AST::Members::Prepend
              prepends.push(Objects::RbsTypes::NamespaceAccess.new(name: member.name.to_s, args: member.args.map(&method(:convert_type))))
            when RBS::AST::Members::InstanceVariable, RBS::AST::Members::ClassVariable, RBS::AST::Members::ClassInstanceVariable
              # TODO: Implement
            when RBS::AST::Members::AttrReader, RBS::AST::Members::AttrWriter, RBS::AST::Members::AttrAccessor
              # TODO: Implement
            when RBS::AST::Members::Alias
              # TODO: Implement
            end
          end

          MembersResult.new(
            instance_methods: instance_methods,
            singleton_methods: singleton_methods,
            includes: includes,
            extends: extends,
            prepends: prepends,
          )
        end

        # @param declaration [RBS::AST::Declarations::Class]
        def process_class(declaration)
          type_params = declaration.type_params.map(&method(:convert_type_param))
          path = path_of(declaration)

          new_context = declaration.type_params.map.with_index { |type_param, idx| [type_param.name, Objects::RbsTypes::ParameterPosition.new(address: path, index: idx)] }.to_h

          derive(namespace: Namespace(path), context: new_context).instance_eval do
            members = traverse_members(declaration, declaration.each_member.to_a)
            decls = declaration.each_decl.to_a.map { |member| traverse(member) }.flatten.compact

            sources = location_to_sources(declaration.location)
            superclass_access = declaration.super_class&.yield_self { |super_class| Objects::RbsTypes::NamespaceAccess.new(name: super_class.name.to_s, args: super_class.args.map(&method(:convert_type))) }

            object_class = Objects::ClassObject.new(
              path: path,
              document: declaration.comment&.string || '',
              sources: sources,
              primary_source: sources.first,
              instance_method_addresses: members.instance_methods.map(&:address),
              superclass_access: superclass_access,
              include_accesses: members.includes,
              prepend_accesses: members.prepends,
              rbs_type_params_overloads: [type_params],
              constant_addresses: decls.select { |decl| decl.is_a?(Objects::ValueObject) }.map { |constant| constant.path },
            )
            object_meta_class = Objects::MetaClassObject.new(
              path: path,
              sources: location_to_sources(declaration.location),
              primary_source: convert_location(declaration.location),
              instance_method_addresses: members.singleton_methods.map(&:address),
              include_accesses: members.extends,
            )

            [object_class, object_meta_class, *members.instance_methods, *members.singleton_methods, *decls]
          end
        end

        # @param declaration [RBS::AST::Declarations::Module]
        def process_module(declaration)
          type_params = declaration.type_params.map(&method(:convert_type_param))
          path = path_of(declaration)

          new_context = declaration.type_params.map.with_index { |type_param, idx| [type_param.name, Objects::RbsTypes::ParameterPosition.new(address: path, index: idx)] }.to_h

          derive(namespace: Namespace(path), context: new_context).instance_eval do
            members = traverse_members(declaration, declaration.each_member.to_a)
            decls = declaration.each_decl.to_a.map { |member| traverse(member) }.flatten.compact

            sources = location_to_sources(declaration.location)

            object_class = Objects::ModuleObject.new(
              path: path,
              document: declaration.comment&.string || '',
              sources: sources,
              primary_source: sources.first,
              instance_method_addresses: members.instance_methods,
              include_accesses: members.includes,
              prepend_accesses: members.prepends,
              rbs_type_params_overloads: [type_params],
              constant_addresses: decls.select { |decl| decl.is_a?(Objects::ValueObject) }.map { |constant| constant.path },
            )
            object_meta_class = Objects::MetaClassObject.new(
              path: path,
              sources: location_to_sources(declaration.location),
              primary_source: convert_location(declaration.location),
              instance_method_addresses: members.singleton_methods,
              include_accesses: members.prepends,
            )

            [object_class, object_meta_class, *members.instance_methods, *members.singleton_methods, *decls]
          end
        end

        # @param declaration [RBS::AST::Declarations::Constant]
        def process_constant(declaration)
          path = path_of(declaration)

          Objects::ValueObject.new(
            path: path,
            rbs_type: convert_type(declaration.type),
          )
        end

        # @param location [RBS::Location, nil]
        # @return [(String, Integer, Integer), nil]
        def convert_location(location)
          file = location&.name
          file = importer.source_path if importer.source_path && file == "(stdin)"
          return nil unless file
          [importer.root_path ? File.expand_path(file, importer.root_path) : file, location.start_line, location.start_column]
        end

        # @param location [RBS::Location, nil]
        # @return [(String, Integer, Integer)]
        def location_to_sources(location)
          [location].compact.map(&method(:convert_location)).compact
        end

        # @type (RBS::Types::t type) -> Objects::RbsTypes::TypeContainer
        def convert_type(type)
          Objects::RbsTypes::TypeContainer.of(
            type: type.to_s,
            free_variables: [find_free_variable(type)].compact,
          )
        end

        # @type (RBS::MethodType method_type) -> Objects::RbsTypes::MethodTypeContainer
        def convert_method_type(method_type)
          free_variables = method_type.each_type.with_object(Set.new) do |type, set|
            free_variable = find_free_variable(type)
            set << free_variable if free_variable
          end

          Objects::RbsTypes::MethodTypeContainer.of(
            type: method_type.to_s,
            free_variables: free_variables.to_a,
          )
        end

        # @type (RBS::Types::t type) -> (Objects::RbsTypes::FreeVariable | nil)
        def find_free_variable(type)
          case type
          when RBS::Types::Variable
            if parameter_position = context[type.name.to_sym]
              Objects::RbsTypes::FreeVariable.new(name: type_param.name, position: parameter_position)
            else
              nil
            end
          else
            nil
          end
        end

        # @param type_param [RBS::AST::TypeParam]
        # @return [Objects::RbsTypes::TypeParam]
        def convert_type_param(type_param)
          Objects::RbsTypes::TypeParam.new(
            name: type_param.name,
            variance: type_param.variance,
            unchecked: type_param.unchecked?,
            upper_bound: type_param.upper_bound&.name&.to_s,
          )
        end

        # @param namespace [RBS::Namespace]
        # @param context [{ Symbol => Objects::RbsTypes::ParameterPosition }]
        # @return [Traverser]
        def derive(namespace: nil, context: {})
          self.class.new(importer, namespace: namespace || self.namespace, context: self.context.merge(context))
        end

        class MembersResult < Struct.new(:instance_methods, :singleton_methods, :includes, :extends, :prepends, keyword_init: true)
        end

        # @param declaration [RBS::AST::Declarations::t]
        # @return [String]
        def path_of(declaration)
          declaration.name.with_prefix(namespace).to_s
        end
      end
    end
  end
end
