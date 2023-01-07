module Yoda
  module Store
    module Query
      class FindMetaClass < Base
        # @param path [String, Model::Path, Model::ScopedPath]
        # @param visitor [Visitor]
        # @return [Objects::NamespaceObject, nil]
        def find(path, visitor: Visitor.new)
          visitor.visit("FindMetaClass.find(#{path})")
          constant = FindConstant.new(registry).find(path, visitor: visitor)
          if constant && meta_class = registry.get(constant.meta_class_address)
            meta_class
          else
            nil
          end
        end
      end
    end
  end
end
