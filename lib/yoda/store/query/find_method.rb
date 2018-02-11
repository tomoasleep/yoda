module Yoda
  module Store
    module Query
      class FindMethod < Base
        # @param namespace [Objects::Namespace]
        # @param method_name [String, Regexp]
        # @return [Objects::MethodObject, nil]
        def find(namespace, method_name)
          lazy_select(namespace, method_name).first
        end

        # @param namespace [Objects::Namespace]
        # @param method_name [String, Regexp]
        # @return [Array<Objects::MethodObject>]
        def select(namespace, method_name)
          lazy_select(namespace, method_name).to_a
        end

        private

        # @param namespace [Objects::Namespace]
        # @param expected [String, Regexp]
        # @return [Enumerator<Objects::MethodObject>]
        def lazy_select(namespace, expected)
          Enumerator.new do |yielder|
            met = Set.new

            all_method_addresses(namespace).each do |address|
              name = Objects::MethodObject.name_of_path(address)
              if match_name?(name, expected)
                next if met.include?(name)
                if el = registry.find(address)
                  met.add(name)
                  yielder << el
                end
              end
            end
          end
        end

        # @param namespace [Objects::Namespace]
        # @return [Enumerator<Objects::MethodObject>]
        def all_method_addresses(namespace)
          Enumerator.new do |yielder|
            Associators::AssociateAncestors.new(registry).associate(namespace)
            namespace.ancestors.each do |ancestor|
              ancestor.instance_method_addresses.each do |address|
                yielder << address
              end
            end
          end
        end

        # @param name [String]
        # @param expected_name_or_pattern [String, Regexp]
        # @return [true, false]
        def match_name?(name, expected_name_or_pattern)
          if expected_name_or_pattern.is_a?(String)
            name == expected_name_or_pattern
          else
            name.match?(expected_name_or_pattern)
          end
        end
      end
    end
  end
end
