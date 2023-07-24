require 'yoda/store/objects/connected_delegation'

module Yoda
  module Store
    module Objects
      module RbsTypes
        class NamespaceAccess
          include Serializable

          # @return [Address]
          attr_reader :name

          # @return [Array<Array<TypeContainer>>]
          attr_reader :args_overloads

          def self.of(param)
            case param
            when NamespaceAccess
              param
            when Hash
              build(param)
            when String, Symbol
              new(name: param)
            when Address
              new(name: param.to_s)
            else
              raise ArgumentError, "Unexpected type: #{param.class}"
            end
          end

          # @param name [Symbol]
          # @param args [Array<String>]
          def initialize(
            name:,
            args: [],
            args_overloads: [[]]
          )
            @name = Address.of(name)
            if args.empty?
              @args_overloads = args_overloads.map { |args| args.map(&TypeContainer.method(:of)) }
            else
              @args_overloads = [args.map(&TypeContainer.method(:of))]
            end
          end

          # @return [Address]
          def address
            name
          end

          # @type (namespace: NamespaceObject, access: NamespaceAccess) -> Instance
          def wrap_namespace(namespace, type_assignments: TypeAssignments.new)
            arg_types_overloads = args_overloads.map do |args|
              args.map { |type_literal| type_literal.to_rbs_type(type_assignments: type_assignments) }
            end

            param_length = arg_types_overloads.map(&:size).max || 0
            arg_types = param_length.times.map do |i|
              types = arg_types_overloads.map { |args| args[i] || RBS::Types::Bases::Any.new(location: nil) }.uniq
              types.length == 1 ? types.first : RBS::Types::Union.new(types: types, location: nil)
            end

            new_type_assignments = param_length.times.map do |i|
              ParameterPosition.new(address: namespace.path, index: i)
            end

            NamespaceWithTypeAssignments.new(
              namespace_object: namespace,
              type_assignments: type_assignments,
            )
          end

          # @param another [NamespaceAccess]
          def merge(another)
            return self if another.nil?
            return another if self == another

            self.class.new(
              name: name,
              args: (args_overloads + another.args_overloads).uniq,
            )
          end

          # @return [Hash]
          def to_h
            {
              name: name.to_s,
              args_overloads: args_overloads.map { |args| args.map(&:to_h) },
            }
          end
        end
      end
    end
  end
end
