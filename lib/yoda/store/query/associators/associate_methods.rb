module Yoda
  module Store
    module Query
      module Associators
        class AssociateMethods
          # @return [Registry]
          attr_reader :registry

          # @param registry [Registry]
          def initialize(registry)
            @registry = registry
          end

          # @param obj [Object::Base]
          # @return [Enumerator<Objects::MethodObject>]
          def associate(obj)
            if obj.is_a?(Objects::NamespaceObject)
              Enumerator.new do |yielder|
                name_set = Set.new

                AssociateAncestors.new(registry).associate(obj).each do |ancestor|
                  ancestor.instance_method_addresses.each do |method_address|
                    method_name = Objects::MethodObject.name_of_path(method_address)
                    if !name_set.member?(method_name)
                      name_set.add(method_name)
                      if el = registry.find(method_address)
                        yielder << el
                      end
                    end
                  end
                end
              end
            else
              []
            end
          end
        end
      end
    end
  end
end
