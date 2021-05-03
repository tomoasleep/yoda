require 'forwardable'

module Yoda
  module Model
    class Environment
      class NamespaceMembers
        # @return [AccessorInterface]
        attr_reader :accessor

        # @return [Environment]
        attr_reader :environment

        # @param accessor [AccessorInterface]
        # @param environment [Environment]
        def initialize(accessor:, environment:)
          @accessor = accessor
          @environment = environment
        end

        # @param name [String, Symbol, Regexp]
        # @param visibility [Array<:private, :public, :protected>]
        # @return [Enumerator<FunctionSignatures::Base>]
        def select_method(name, visibility:)
          rbs_method_signatures = begin
            method_defs = filter_rbs_methods(name, visibility: visibility)
            method_defs.flat_map do |method_def|
              method_def.defs.map do |type_def|
                FunctionSignatures::RbsMethod.new(
                  rbs_definition: accessor.rbs_definition,
                  rbs_method_definition: method_def,
                  rbs_method_typedef: type_def,
                )
              end
            end
          end

          stored_signatures = stored_method_members&.select_signature(name, visibility: visibility) || []

          (rbs_method_signatures + stored_signatures).map { |sig| sig.wrap(environment) }
        end

        # @param name [String, Symbol]
        # @return [Array<Symbol>]
        def select_constant_paths(name)
          # TODO: Search RBS
          stored_consts = stored_constant_members&.select(name) || []
          stored_consts.map(&:path)
        end

        # @param name [String, Symbol]
        # @return [RBS::Types::t]
        def select_constant_type(name)
          paths = select_constant_paths(name)

          types = paths.flat_map do |path|
            RBS::Types::ClassSingleton.new(
              name: accessor.environment.resolve_rbs_type_name(path),
              location: nil,
            )
          end

          RBS::Types::Union.new(types: types, location: nil)
        end

        private

        # @param pattern [String, Symbol, Regexp]
        # @param visibility [Array<:private, :public, :protected>]
        # @return [Array<RBS::Definition::Method>]
        def filter_rbs_methods(pattern, visibility:)
          return [] unless rbs_methods
          if pattern.is_a?(Regexp)
            rbs_methods.select do |(key, value)|
              key.to_s.match?(pattern) && visibility.include?(value.accesibility)
            end.map { |(key, value)| value }
          else
            meth = rbs_methods[pattern.to_sym]
            meth && visibility.include?(meth.accessibility) ? [meth] : []
          end
        end

        # @return [Hash<Symbol => RBS::Definition::Method>]
        def rbs_methods
          accessor.rbs_definition&.methods
        end

        # @return [Store::Query::MethodMemberSet, nil]
        def stored_method_members
          accessor.class_object&.method_members
        end

        # @return [Store::Query::ConstantMemberSet, nil]
        def stored_constant_members
          accessor.self_object&.constant_members
        end
      end
    end
  end
end
