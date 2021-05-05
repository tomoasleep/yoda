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
          scoped_path = Model::ScopedPath.new([object.path], name)
          [FindConstant.new(registry).find(scoped_path, **kwargs)].compact
        end
      end
    end
  end
end
