module Yoda
  module Store
    module Query
      class MethodMemberSet
        # @return [Registry]
        attr_reader :registry

        # @return [Objects::NamespaceObject]
        attr_reader :object

        # @param object [Objects::NamespaceObject]
        # @param registry [Registry]
        # @param origin [AncestorTree]
        def initialize(registry:, object:)
          @registry = registry
          @object = object
        end

        # @return [Enumerator<Objects::MethodObject>]
        def to_enum(**kwargs)
          FindMethod.new(registry).all(object, **kwargs)
        end

        # @param method_name [String, Regexp]
        # @return [Objects::MethodObject, nil]
        def find(method_name, **kwargs)
          FindMethod.new(registry).find(object, method_name, **kwargs)
        end

        # @param method_name [String, Regexp]
        # @return [Enumerator<Objects::MethodObject>]
        def select(method_name, **kwargs)
          FindMethod.new(registry).select(object, method_name, **kwargs)
        end

        # @param method_name [String, Regexp]
        # @return [Model::FunctionSignatures::Base]
        def find_signature(method_name, **kwargs)
          FindSignature.new(registry).select(object, method_name, **kwargs).first
        end

        # @param method_name [String, Regexp]
        # @return [Array<Model::FunctionSignatures::Base>]
        def select_signature(method_name, **kwargs)
          FindSignature.new(registry).select(object, method_name, **kwargs)
        end
      end
    end
  end
end
