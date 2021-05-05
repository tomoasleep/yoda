module Yoda
  module Store
    module Query
      class FindMethod < Base
        # @param namespace [Objects::NamespaceObject]
        # @param method_name [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @return [Objects::MethodObject, nil]
        def find(namespace, method_name, visibility: nil)
          lazy_select(namespace, method_name, visibility: visibility).first
        end

        # @param namespace [Objects::Namespace]
        # @param method_name [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @return [Array<Objects::MethodObject>]
        def select(namespace, method_name, visibility: nil)
          lazy_select(namespace, method_name, visibility: nil).to_a
        end

        private

        # @param namespace [Objects::Namespace]
        # @param expected [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @return [Enumerator<Objects::MethodObject>]
        def lazy_select(namespace, expected, visibility: nil)
          visibility ||=  %i(public private protected)
          Enumerator.new do |yielder|
            Associators::AssociateMethods.new(registry).associate(namespace).each do |method|
              if match_name?(method.name, expected) && visibility.include?(method.visibility)
                yielder << method
              end
            end
          end
        end

        # @param name [String]
        # @param expected_name_or_pattern [String, Regexp]
        # @return [true, false]
        def match_name?(name, expected_name_or_pattern)
          case expected_name_or_pattern
          when String
            name == expected_name_or_pattern
          when Regexp
            name.match?(expected_name_or_pattern)
          else
            fail ArgumentError, expected_name_or_pattern
          end
        end
      end
    end
  end
end
