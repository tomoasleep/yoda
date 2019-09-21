module Yoda
  module Store
    module Query
      class FindSignature < Base
        # @param namespace [Objects::NamespaceObject]
        # @param method_name [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @return [Array<Objects::MethodObject>]
        def select(namespace, method_name, visibility: nil)
          FindMethod.new(registry).select(namespace, method_name, visibility: visibility).flat_map { |el| build(namespace, el) }
        end

        # @param namespaces [Array<Objects::NamespaceObject>]
        # @param method_name [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @return [Array<Objects::MethodObject>]
        def select_on_multiple(namespaces, method_name, visibility: nil)
          namespaces.flat_map { |namespace| select(namespace, method_name, visibility: visibility) }
        end

        private

        # @param receiver [Store::Objects::NamespaceObject]
        # @param method_object [Store::Objects::MethodObject]
        # @return [Array<FunctionSignatures::Base>]
        def build(receiver, method_object)
          if constructor = try_to_build_constructor(receiver, method_object)
            [constructor]
          elsif method_object.overloads.empty?
            [Model::FunctionSignatures::Method.new(method_object)]
          else
            method_object.overloads.map { |overload| Model::FunctionSignatures::Overload.new(method_object, overload) }
          end
        end

        # @param receiver [Store::Objects::NamespaceObject]
        # @param method_object [Store::Objects::MethodObject]
        # @return [FunctionSignatures::Constructor, nil]
        def try_to_build_constructor(receiver, method_object)
          if method_object.path == 'Class#new' && receiver.is_a?(Store::Objects::MetaClassObject) && receiver.path != 'Class'
            base_class = registry.get(receiver.base_class_address) || return
            initialize_object = FindMethod.new(registry).find(base_class, 'initialize') || return
            Model::FunctionSignatures::Constructor.new(base_class, initialize_object)
          else
            nil
          end
        end
      end
    end
  end
end
