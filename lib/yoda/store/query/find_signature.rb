module Yoda
  module Store
    module Query
      class FindSignature < Base
        # @param namespace [Objects::NamespaceObject]
        # @param method_name [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @param source [Array<:myself, :ancestors>, nil]
        # @return [Array<Model::FunctionSignatures::Base>]
        def select(namespace, method_name, visibility: nil, source: nil)
          FindMethod.new(registry).select(namespace, method_name, visibility: visibility, source: source).flat_map { |el| build(namespace, el) }
        end

        # @param namespaces [Array<Objects::NamespaceObject>]
        # @param method_name [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @param source [Array<:myself, :ancestors>, nil]
        # @return [Array<Model::FunctionSignatures::Base>]
        def select_on_multiple(namespaces, method_name, visibility: nil, source: nil)
          namespaces.flat_map { |namespace| select(namespace, method_name, visibility: visibility, source: source) }
        end

        private

        # @param receiver [Store::Objects::NamespaceObject]
        # @param method_object [Store::Objects::MethodObject]
        # @return [Array<FunctionSignatures::Base>]
        def build(receiver, method_object)
          method_object = method_object.with_connection(registry: registry)

          if constructor = try_to_build_constructor(receiver, method_object)
            [constructor]
          elsif method_object.overloads.empty?
            [Model::FunctionSignatures::Method.new(method_object)]
          else
            method_object.overloads.map { |overload| Model::FunctionSignatures::Overload.new(method_object.with_connection(registry: registry), overload) }
          end
        end

        # @param receiver [Store::Objects::NamespaceObject]
        # @param method_object [Store::Objects::MethodObject]
        # @return [FunctionSignatures::Constructor, nil]
        def try_to_build_constructor(receiver, method_object)
          if method_object.path == 'Class#new' && receiver.kind == :meta_class && receiver.path != 'Class'
            base_class = registry.get(receiver.base_class_address)&.with_connection(registry: registry) || return
            initialize_object = FindMethod.new(registry).find(base_class, 'initialize')&.with_connection(registry: registry) || return
            Model::FunctionSignatures::Constructor.new(base_class, initialize_object)
          else
            nil
          end
        end
      end
    end
  end
end
