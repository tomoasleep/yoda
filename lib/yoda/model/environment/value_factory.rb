require 'rbs'

module Yoda
  module Model
    class Environment
      # Environment can instanciate {Values::Base} objects from rbs types
      class ValueFactory
        # @return [Environment]
        attr_reader :environment

        # @param project [Store::Project]
        def self.from_environment(environment)
          new(environment: environment)
        end

        # @param environment [Environment]
        def initialize(environment:)
          @environment = environment
        end

        # @param type [RBS::Types::Bases::Base, RBS::Types::Variable, RBS::Types::ClassSingleton, RBS::Types::Interface, RBS::Types::ClassInstance, RBS::Types::Alias, RBS::Types::Tuple, RBS::Types::Record, RBS::Types::Optional, RBS::Types::Union, RBS::Types::Intersection, RBS::Types::Function, RBS::Types::Block, RBS::Types::Proc, RBS::Types::Literal]
        # @return [Values::Base, nil]
        def resolve_value_by_rbs_type(type)
          case type
          when RBS::Types::Bases::Any
            Values::EmptyValue.new
          when RBS::Types::Bases::Top
            # TODO: Implement as everything.
            Values::EmptyValue.new
          when RBS::Types::Bases::Bottom
            Values::EmptyValue.new
          when RBS::Types::Bases::Void
            Values::EmptyValue.new
          when RBS::Types::Bases::Bool
            Values::UnionValue.new(
              resolve_instance_by_rbs_type_name(TypeName("::TrueClass")),
              resolve_instance_by_rbs_type_name(TypeName("::FalseClass")),
            )
          when RBS::Types::Bases::Nil
            resolve_instance_by_rbs_type_name(TypeName("::NilClass"))
          when RBS::Types::ClassSingleton
            resolve_singleton_by_rbs_type_name(type.name)
          when RBS::Types::ClassInstance
            resolve_instance_by_rbs_type_name(type.name, args: type.args)
          when RBS::Types::Interface
            args = type.args.map {|arg| resolve_value_by_rbs_type(arg) }

            resolve_interface_by_rbs_type_name(type.name, args: type.args)
          when RBS::Types::Union
            Values::UnionValue.new(
              *type.types.flat_map { |ty| resolve_value_by_rbs_type(ty) }
            )
          when RBS::Types::Optional
            Values::UnionValue.new(
              resolve_instance_by_rbs_type_name(type.type.name, args: type.args),
              resolve_instance_by_rbs_type_name(TypeName("::NilClass")),
            )
          when RBS::Types::Intersection
            Values::IntersectionValue.new(
              *type.types.map { |ty| resolve_value_by_rbs_type(ty) }
            )
          when RBS::Types::Literal
            literal_instance(type.literal)
          when RBS::Types::Tuple
            # TODO: Implement as tuple
            # Values::Tuple.new(value_lists: type.types.map { |ty| resolve_value_by_rbs_type(ty) })

            resolve_instance_by_rbs_type_name(TypeName("::Array"))
          when RBS::Types::Record
            # TODO: Implement as record
            # Values::Tuple.new(values_map: type.fields.map { |(key, value)| [key, resolve_value_by_rbs_type(value)] }.to_h)
            resolve_instance_by_rbs_type_name(TypeName("::Hash"))
          when RBS::Types::Proc
            # TODO: Implement as proc
            # Values::Proc.new("::Proc", type_args: type)
            resolve_instance_by_rbs_type_name(TypeName("::Proc"))
          when RBS::Types::Alias
            rbs_alias = environment.rbs_environment.alias_decls[type.name]&.decl

            if rbs_alias
              resolve_value_by_rbs_type(rbs_alias.type)
            else
              Values::EmptyValue.new
            end
          when RBS::Types::Variable
            Logger.warn("Value factory does not has proper information to convert #{type}.")
            Values::EmptyValue.new
          when RBS::Types::Bases::Self, RBS::Types::Bases::Class, RBS::Types::Bases::Instance
            Logger.warn("Value factory does not has proper information to convert #{type}.")
            Values::EmptyValue.new
          else
            raise "Unexpected type given: #{type}"
          end
        end

        private

        # @param rbs_type_name [RBS::TypeName]
        # @param args [Array<RBS::Types::t]
        # @return [Values::InstanceValue]
        def resolve_instance_by_rbs_type_name(rbs_type_name, args: [])
          accessor = InstanceAccessor.new(environment: environment, path: rbs_type_name.to_s, type_args: args)
          Values::InstanceValue.new(accessor)
        end

        # @param rbs_type_name [RBS::TypeName]
        # @param args [RBS::Types::t]
        # @return [Values::InstanceValue]
        def resolve_singleton_by_rbs_type_name(rbs_type_name, args: [])
          accessor = InstanceAccessor.new(environment: environment, path: rbs_type_name.to_s, type_args: args).singleton_accessor
          Values::InstanceValue.new(accessor)
        end

        # @param rbs_type_name [RBS::TypeName]
        # @param args [RBS::Types::t]
        # @return [Valuess::InstanceValue]
        def resolve_interface_by_rbs_type_name(rbs_type_name, args: [])
          accessor = InstanceAccessor.new(environment: environment, path: rbs_type_name.to_s, type_args: args)
          Values::InstanceValue.new(accessor)
        end

        def literal_instance(literal)
          type_name = TypeName(literal.class.name)
          value = resolve_instance_by_rbs_type_name(type_name)

          Values::LiteralValue.new(value: value, literal: literal)
        end
      end
    end
  end
end
