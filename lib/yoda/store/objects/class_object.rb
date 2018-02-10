module Yoda
  module Store
    module Objects
      class ClassObject < NamespaceObject
        # @return [String, nil]
        attr_reader :superclass_address

        # @param path [String]
        # @param superclass_address [String, nil]
        def initialize(superclass_address: nil, **kwargs)
          super(kwargs)
          @superclass_address = superclass_address
        end

        def kind
          :class
        end

        def to_h
          super.merge(superclass_address: superclass_address)
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          super.merge(
            superclass_address: select_superclass(another.superclass_address),
          )
        end

        # @param another [String]
        # @return [String]
        def select_superclass(another)
          if %w(Object Exception).include?(another)
            superclass_address || another
          else
            another || superclass_address
          end
        end
      end
    end
  end
end
