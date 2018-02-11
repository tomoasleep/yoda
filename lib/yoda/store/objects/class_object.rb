module Yoda
  module Store
    module Objects
      class ClassObject < NamespaceObject
        # @return [ScopedPath, nil]
        attr_reader :superclass_path

        # @param path [String]
        # @param superclass_path [String, nil]
        def initialize(superclass_path: nil, **kwargs)
          super(kwargs)

          @superclass_path = Model::ScopedPath.new(Objects.lexical_scopes_of(path), superclass_path) if superclass_path
        end

        def kind
          :class
        end

        def to_h
          super.merge(superclass_path: superclass_path&.path)
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          super.merge(
            superclass_path: select_superclass(another.superclass_path),
          )
        end

        # @param another [ScopedPath]
        # @return [ScopedPath]
        def select_superclass(another)
          if %w(Object Exception).include?(another&.path&.to_s)
            superclass_path || another
          else
            another || superclass_path
          end
        end
      end
    end
  end
end
