require 'set'

module Yoda
  module Store
    module Query
      module Associators
        # @deprecated Use {AncestorTree} instead.
        class AssociateAncestors
          # @return [Registry]
          attr_reader :registry

          # @param registry [Registry]
          def initialize(registry)
            @registry = registry
          end

          # @param obj [Objects::Base]
          # @param visitor [Visitor]
          # @return [Enumerator<Objects::NamespaceObject>]
          def associate(obj, visitor: Visitor.new)
            Logger.trace("AssociateAncestors.associate(#{obj.address})")
            if obj.is_a?(Objects::NamespaceObject)
              AncestorTree.new(registry: registry, object: obj, visitor: visitor).ancestors
            else
              []
            end
          end
        end
      end
    end
  end
end
