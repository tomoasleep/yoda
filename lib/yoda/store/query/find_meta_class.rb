module Yoda
  module Store
    module Query
      class FindMetaClass < Base
        # @param path [String, Model::Path, Model::ScopedPath]
        # @return [Objects::NamespaceObject, nil]
        def find(path)
          constant = FindConstant.new(registry).find(path)
          if constant && meta_class = registry.find(Objects::MetaClassObject.address_of(constant.path))
            meta_class
          else
            nil
          end
        end
      end
    end
  end
end
