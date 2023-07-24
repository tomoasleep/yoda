require 'forwardable'

module Yoda
  module Store
    module Objects
      module RbsTypes
        class NamespaceWithTypeAssignments
          extend Forwardable

          # @return [Objects::NamespaceObject]
          attr_reader :namespace_object

          # @return [Objects::RbsTypes::TypeAssignments]
          attr_reader :type_assignments

          delegate %i(kind instance_method_addresses include_accesses prepend_accesses constant_addresses rbs_type_params_overloads ancestors methods namespace?) => :namespace_object
          delegate %i(base_class_address) => :namespace_object
          delegate %i(superclass_access) => :namespace_object

          # @param namespace [NamespaceObject]
          # @param type_assignments [{ParameterPosition => TypeContainer}, TypeAssignments]
          def initialize(
            namespace_object:,
            type_assignments:
          )
            @namespace_object = namespace_object
            @type_assignments = Objects::RbsTypes::TypeAssignments.of(type_assignments)
          end

          # @return [NamespaceWithTypeAssignments]
          def superclass
            if superclass_obj = ancestor_tree.superclass.with_connection(**connection_options)
              NamepsaceWithTypeAssignments.new(
                namespace_object: superclass_obj,
                type_assignments: type_assignments.merge(superclass_access.type_assignments),
              )
            end
          end

          # @return [Enumerator::Lazy<NamespaceWithTypeAssignments>]
          def ancestors
            namespace_object.ancestors.lazy.map(&method(:wrap))
          end

          # @return [Enumerator::Lazy<NamespaceObject::Connected>]
          def mixins
            namespace_object.mixins.lazy.map(&method(:wrap))
          end

          # @return [Query::MethodMemberSet]
          def method_members
            namespace_object.method_members.with_type_assignments(type_assignments)
          end

          # @return [Query::ConstantMemberSet]
          def constant_members
            namespace_object.constant_members.with_type_assignments(type_assignments)
          end

          private

          def wrap(object)
            NamespaceWithTypeAssignments.new(
              namespace_object: object,
              type_assignments: type_assignments,
            )
          end
        end
      end
    end
  end
end
