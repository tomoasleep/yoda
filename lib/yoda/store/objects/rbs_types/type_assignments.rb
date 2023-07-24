require 'yoda/store/objects/connected_delegation'

module Yoda
  module Store
    module Objects
      module RbsTypes
        class TypeAssignments
          # @type (Instance | String) -> Instance
          def self.of(assignments)
            return assignments if assignments.is_a?(self)

            new(assignments)
          end

          # @return [{ParameterPosition => TypeContainer}}]
          attr_reader :assignments

          # @type (Hash[ParameterPosition, TypeContainer] assignments) -> Instance
          def initialize(assignments = {})
            @assignments = assignments.to_h { |key, value| [ParameterPosition.of(key), TypeContainer.of(value)] }
          end

          # @type (Array[FreeVariable] free_variables) -> Hash[Symbol, TypeContainer]
          def make_variable_map(free_variables)
            free_variables.each_with_object({}) do |variable_map, free_variable|
              type = assignments[free_variable.position]
              variable_map[variable.name] = type if type
            end
          end

          # @type (Array[ParameterPositions] *parameter_positions) -> Self
          def slice(*parameter_positions)
            self.class.of(assignments.slice(*parameter_positions))
          end

          # @param names_to_avoid [Enumerable<Symbol>]
          # @return [self]
          def rename_free_variables(names_to_avoid = [])
            names_to_avoid = Set.new(names_to_avoid.map(&:to_sym))

            new_assignments = assignments.to_h.with_object(names_to_avoid) do |(position, type), names_to_avoid|
              new_type = type.rename_free_variables(names_to_avoid)
              names_to_avoid += new_type.free_variables.map(&:name)

              [position, new_type]
            end

            self.class.of(new_assignments)
          end

          # @param another [TypeAssignments]
          # @return [TypeAssignments]
          def merge(another)
            self.class.of(assignments.merge(TypeAssignments.of(another).assignments))
          end

          private

          # @type (Array[FreeVariable] free_variables) -> (RBS::Type::t) -> RBS::Types::t
          def make_type_mapper(free_variable)
            map = make_variable_map(free_variable)

            ->(type) do
              case type
              when RBS::Types::Variable
                map[type.name] || type
              else
                type
              end
            end
          end
        end
      end
    end
  end
end
