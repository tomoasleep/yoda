module Yoda
  module Store
    module Objects
      class MetaClassObject < NamespaceObject
        # @param path [String]
        # @param document [Document, nil]
        # @param tag_list [TagList, nil]
        # @param instance_method_paths [Array<String>]
        # @param instance_mixin_paths [Array<String>]
        def initialize(path:, **kwargs)
          super
        end

        # @return [String]
        def name
          @name ||= path.match(MODULE_TAIL_PATTERN) { |md| md[1] || md[2] }
        end

        def type
          :meta_class
        end

        def address
          "#{path}.class"
        end
      end
    end
  end
end
