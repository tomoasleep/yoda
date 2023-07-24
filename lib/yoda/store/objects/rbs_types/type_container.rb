require 'yoda/store/objects/connected_delegation'

module Yoda
  module Store
    module Objects
      module RbsTypes
        class TypeContainer
          include Serializable

          # @type (Instance | String) -> Instance
          def self.of(type)
            return type if type.is_a?(self)
            return new(type: type) if type.is_a?(String) || type.is_a?(Symbol)

            build(type)
          end

          # @return [Array<FreeVariable>]
          attr_reader :free_variables

          # @type (type?: RBS::Type::t | String | Symbol, free_variables?: Array[FreeVariable, Hash]) -> Instance
          def initialize(type:, free_variables: [])
            if type.is_a?(String) || type.is_a?(Symbol)
              @type_string = type.to_s
            else
              @type = type
            end
            @free_variables = free_variables.map(&FreeVariable.method(:of))
          end

          # @return [String]
          def type_string
            @type_string ||= @type.to_s
          end

          # @return [String]
          def to_s
            type_string
          end

          # @return [Hash]
          def to_h
            {
              type: type_string,
              free_variables: free_variables.map(&:to_h),
            }
          end

          # @type () -> RBS::Types::MethodType
          def to_rbs_type(type_assignments: nil)
            if type_assignments
              type_assignments.make_type_mapper(free_variables).call(parsed)
            else
              type
            end
          end

          # @param name [Symbol]
          # @param new_name [Symbol]
          # @return [self]
          def rename_variable(name, new_name)
            new_type = type.map_type do |type|
              case type
              when RBS::Types::Variable
                type.name == name ? type.with(name: new_name) : type
              else
                type
              end
            end

            new_free_variables = free_variables.map do |free_variable|
              if v.name == name
                FreeVariable.new(name: new_name, position: v.position)
              else
                v
              end
            end
            self.class.new(type: new_type, free_variables: new_free_variables)
          end

          # @param names_to_avoid [Enumerable<Symbol>]
          def rename_free_variables(names_to_avoid = [])
            names_to_avoid = Set.new(names_to_avoid.map(&:to_sym))

            # @type (Symbol) -> Symbol
            generate_new_name = ->(name) {
              if names_to_avoid.include?(name)
                generate_new_name.call("#{name}_".to_sym)
              else
                name
              end
            }

            renames = {}
            new_free_variables = free_variables.map do |free_variable|
              new_name = generate_new_name(free_variable.name)
              if new_name != free_variable.name
                names_to_avoid.add(name)
                renames.add(name => new_name)
              end
            end

            renames.each_with_object(self) do |obj, (name, new_name)|
              obj.rename_variable(name, new_name)
            end
          end

          # @return [Array<Symbol>]
          def variables
            type.free_variables
          end

          # @param type_assignment [TypeAssignments]
          # @return [self]
          def with_assignments(type_assignments)
            matched_assignments = type_assignments.slice(free_variables.map(&:position).uniq)

            variable_to_type_container = type_assignment.make_variable_map(free_variables)
            existing_free_variables = free_variables.dup

            mapped = type.map_type do |type|
              case type
              when RBS::Types::Variable
                if type_container = variable_to_type_container[type.name]
                  type_mount = type_container.rename_free_variables(existing_free_variables.map(&:name))

                  existing_free_variables << type_mount.free_variables
                  type_mount.type
                else
                  type
                end
              else
                type
              end
            end
          end

          private

          # @type () -> RBS::Types::t
          def type
            @type ||= RBS::Parser.parse_type(@type_string)
          end
        end
      end
    end
  end
end
