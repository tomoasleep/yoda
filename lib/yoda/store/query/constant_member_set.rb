module Yoda
  module Store
    module Query
      class ConstantMemberSet
        # @return [Registry]
        attr_reader :registry

        # @return [Objects::NamespaceObject]
        attr_reader :object

        # @param object [Objects::NamespaceObject]
        # @param registry [Registry]
        def initialize(registry:, object:)
          @registry = registry
          @object = object
        end

        # @param name [String]
        # @return [Objects::Base, nil]
        def find(name, **kwargs)
          scoped_path = Model::ScopedPath.new([object.path], name)
          FindConstant.new(registry).find(scoped_path, **kwargs)
        end

        # @param name [String]
        # @return [Enumerator<Objects::Base>]
        def select(name, **kwargs)
          FindConstant.new(registry).select_by_base_and_pattern(base: object, pattern: name)
        end
      end
    end
  end
end
