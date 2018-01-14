module Yoda
  module Store
    module CodeObject
      class ClassObject < Base
        attr_reader :registry, :class_object

        # @param class_object [Registry]
        # @param class_object [YARD::CodeObject::ClassObject]
        def initailize(registry, class_object)
          @registry = registry
          @class_object = class_object
        end
      end
    end
  end
end
