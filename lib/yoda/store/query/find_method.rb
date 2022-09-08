module Yoda
  module Store
    module Query
      class FindMethod < Base
        ALL_SOURCE = %i(myself ancestors)

        # @param namespace [Objects::NamespaceObject]
        # @param method_name [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @return [Objects::MethodObject, nil]
        def find(namespace, method_name, **kwargs)
          lazy_select(namespace, method_name, **kwargs).first
        end

        # @param namespace [Objects::Namespace]
        # @param method_name [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @return [Array<Objects::MethodObject>]
        def select(namespace, method_name, visibility: nil, source: nil)
          lazy_select(namespace, method_name, visibility: visibility, source: source).to_a
        end

        # @param namespace [Objects::Namespace]
        # @param visibility [Array<Symbol>, nil]
        # @return [Enumerator<Objects::MethodObject>]
        def all(namespace, visibility: nil, source: nil)
          lazy_select(namespace, //, visibility: visibility, source: source)
        end

        private

        # @param namespace [Objects::Namespace]
        # @param expected [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @return [Enumerator<Objects::MethodObject>]
        def lazy_select(namespace, expected, visibility: nil, source: nil)
          visibility ||=  %i(public private protected)

          Enumerator.new do |yielder|
            Associators::AssociateMethods.new(registry).associate(namespace).each do |method|
              if match_method?(namespace, method, name: expected, visibility: visibility, source: source)
                yielder << method
              end
            end
          end
        end

        # @param owner [Objects::Namespace]
        # @param method [Objects::MethodObject]
        # @param name [String, Regexp]
        # @param visibility [Array<Symbol>]
        # @param source [Array<:myself, :ancestors>, nil]
        # @return [Boolean]
        def match_method?(owner, method, name:, visibility:, source:)
          match_name?(method.name, name) &&
            visibility.include?(method.visibility) &&
            match_source?(owner, method, source)
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

        # @param owner [Objects::Namespace]
        # @param method [Objects::MethodObject]
        # @param source [Array<:myself, :ancestors>, nil]
        # @return [Boolean]
        def match_source?(owner, method, source)
          return true unless source
          if owner == method.namespace
            source.include?(:myself)
          else
            source.include?(:ancestors)
          end
        end
      end
    end
  end
end
