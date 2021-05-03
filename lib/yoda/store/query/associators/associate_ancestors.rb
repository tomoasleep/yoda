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
          # @return [Enumerator<Objects::NamespaceObject>]
          def associate(obj)
            if obj.is_a?(Objects::NamespaceObject)
              AncestorTree.new(registry: registry, object: obj).ancestors
            else
              []
            end
          end
        end
      end
    end
  end
end
