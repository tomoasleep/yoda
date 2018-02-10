module Yoda
  module Store
    module Objects
      class MetaClassObject < NamespaceObject
        # @param path [String]
        # @return [String]
        def self.address_of(path)
          "#{path}%class"
        end

        # @param path [String]
        # @param document [Document, nil]
        # @param tag_list [TagList, nil]
        # @param instance_method_paths [Array<String>]
        # @param instance_mixin_paths [Array<String>]
        def initialize(**kwargs)
          super(kwargs)
        end

        # @return [String]
        def name
          @name ||= path.match(MODULE_TAIL_PATTERN) { |md| md[1] || md[2] }
        end

        def kind
          :meta_class
        end

        def address
          MetaClassObject.address_of(path)
        end
      end
    end
  end
end
