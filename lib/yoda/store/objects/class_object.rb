module Yoda
  module Store
    module Objects
      class ClassObject < NamespaceObject
        class Connected < NamespaceObject::Connected
          delegate_to_object :superclass_access

          # @return [NamespaceObject::Connected]
          def superclass
            ancestor_tree.superclass.with_connection(**connection_options)
          end
        end

        # @return [RbsTypes::NamespaceAccess, nil]
        attr_reader :superclass_access

        # @return [Array<Symbol>]
        def self.attr_names
          super + %i(superclass_access)
        end

        # @param path [String, Hash, RbsTypes::NamespaceAccess]
        # @param superclass_access [String, nil]
        def initialize(superclass_access: nil, **kwargs)
          super(**kwargs)

          @superclass_access = RbsTypes::NamespaceAccess.of(superclass_access) if superclass_access
        end

        def kind
          :class
        end

        def to_h
          super.merge(superclass_access: superclass_access&.to_h)
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          super.merge(
            superclass_access: select_superclass(another.superclass_access)&.to_h,
          )
        end

        # @param another [NamespaceAccess]
        # @return [NamespaceAccess]
        def select_superclass(another)
          if %w(Object Exception).include?(another&.address&.to_s)
            superclass_access || another
          else
            another || superclass_access
          end
        end
      end
    end
  end
end
