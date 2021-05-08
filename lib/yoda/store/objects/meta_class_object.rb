module Yoda
  module Store
    module Objects
      # @todo Rename to SingletonClassObject
      class MetaClassObject < NamespaceObject
        class Connected < NamespaceObject::Connected
          delegate_to_object :base_class_address

          # @return [NamespaceObject::Connected]
          def superclass
            ancestor_tree.superclass.with_connection(**connection_options)
          end

          # @return [Base::Connected, nil]
          def instance
            registry.get(path)&.with_connection(**connection_options)
          end
        end

        # @param path [String]
        # @return [String]
        def self.address_of(path)
          "#{path}%class"
        end

        # @param address [String]
        # @return [true, false]
        def self.meta_class_address?(address)
          address.end_with?('%class')
        end

        # @param address [String]
        # @return [String]
        def self.path_of(address)
          address.sub(/%class$/, '')
        end

        # @param path [String]
        # @param document [Document, nil]
        # @param tag_list [TagList, nil]
        # @param instance_method_paths [Array<String>]
        # @param instance_mixin_paths [Array<String>]
        def initialize(**kwargs)
          super(**kwargs)
        end

        # @return [String]
        def name
          @name ||= path.match(MODULE_TAIL_PATTERN) { |md| md[1] || md[2] }
        end

        def kind
          :meta_class
        end

        # @return [String]
        def address
          MetaClassObject.address_of(path)
        end

        # @return [String]
        def base_class_address
          path
        end
      end
    end
  end
end
