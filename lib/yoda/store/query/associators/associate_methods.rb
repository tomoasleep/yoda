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
          # @param visitor [Visitor]
          # @return [Enumerator<Objects::MethodObject>]
          def associate(obj, visitor: Visitor.new)
            visitor.visit("AssociateMethods.associate(#{obj.address})")
            if obj.namespace?
              Enumerator.new do |yielder|
                name_set = Set.new

                AssociateAncestors.new(registry).associate(obj, visitor: visitor).each do |ancestor|
                  ancestor.instance_method_addresses.each do |method_address|
                    method_name = Address.of(method_address).name
                    if !name_set.member?(method_name)
                      name_set.add(method_name)
                      if el = registry.get(method_address)
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
