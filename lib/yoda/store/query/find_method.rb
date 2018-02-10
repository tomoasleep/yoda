module Yoda
  module Store
    module Query
      class FindMethod < Base
        # @param namespace [Objects::Namespace]
        # @param method_name [Objects::MethodObject]
        # @return [Objects::MethodObject, nil]
        def find(namespace, method_name)
          Associators::AssociateAncestors.new(registry).associate(namespace)
          namespace.ancestors.each do |ancestor|
            ancestor.instance_method_addresses.each do |method_address|
              name = Objects::MethodObject.name_of_path(method_address)
              if method_name = name && el = registry.find(method_address)
                return el
              end
            end
          end
          nil
        end
      end
    end
  end
end
