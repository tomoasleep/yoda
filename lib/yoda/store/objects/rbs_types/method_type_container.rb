require 'yoda/store/objects/connected_delegation'

module Yoda
  module Store
    module Objects
      module RbsTypes
        class MethodTypeContainer
          include Serializable

          # @type (Instance | String) -> Instance
          def self.of(type)
            return type if type.is_a?(self)
            return new(type: type) if type.is_a?(String) || type.is_a?(Symbol)

            build(type)
          end

          # @return [String]
          attr_reader :type

          # @return [Array<FreeVariable>]
          attr_reader :free_variables

          # @param type [String, Symbol, RBS::MethodType]
          # @param free_variables [Array<FreeVariable, Hash>]
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

          # @type (TypeAssignments type_assignments?) -> RBS::Types::MethodType
          def to_rbs_method_type(type_assignments: nil)
            if type_assignments
              type.map_type(&type_assignments.make_type_mapper(free_variables))
            else
              type
            end
          end

          # @return [Model::FunctionSignatures::ParameterList]
          def to_parameter_list
            Model::FunctionSignatures::ParameterList.from_rbs_method_type(to_rbs_method_type)
          end

          # @param names_to_avoid [Enumerable<Symbol>]
          # @return [self]
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

          # @param name [Symbol]
          # @param new_name [Symbol]
          # @return [self]
          def rename_variable(name, new_name)
            new_type_container = type_container.rename_variable(name, new_name)
            new_block_container = block_container&.rename_variable(name, new_name)

            new_method_type = RBS::MethodType.new(
              type_params: type.type_params.map { |param| param.rename_variable(name, new_name) },
              type: new_type_container.type,
              block: new_block_container&.type,
              location: type.location,
            )

            self.class.new(type: new_method_type, free_variables: new_type_container.free_variables)
          end

          # @param type_assignment [TypeAssignments]
          # @return [self]
          def with_assignments(type_assignments)
            renamed_type_assignments = type_assignments.rename_free_variables(type_params.map(&:name))

            new_type_container = type_container.rename_variable(renamed_type_assignments)
            new_block_container = type_container.rename_variable(renamed_type_assignments)

            new_method_type = RBS::MethodType.new(
              type_params: type.type_params,
              type: new_type_container.type,
              block: new_block_container&.type,
              location: type.location,
            )

          end

          private

          # @type () -> RBS::MethodType
          def type
            @type ||= RBS::Parser.parse_method_type(@type_string)
          end

          # @return [TypeParam]
          def type_params
            type.type_params.map { |type_param| TypeParam.of(type_param) }
          end

          # @return [TypeContainer]
          def type_container
            TypeContainer.new(type: type.type, free_variables: free_variables)
          end

          # @return [TypeContainer]
          def block_container
            type.block && TypeContainer.new(type: type.block, free_variables: free_variables)
          end
        end
      end
    end
  end
end
