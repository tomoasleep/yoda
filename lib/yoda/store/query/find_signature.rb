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
          overloads = method_overloads(method_object)

          if constructor = try_to_build_constructor(receiver, method_object)
            [constructor]
          elsif overloads.empty?
            [Model::FunctionSignatures::Method.new(method_object)]
          else
            overloads.map { |overload| Model::FunctionSignatures::Overload.new(method_object.with_connection(registry: registry), overload) }
          end
        end

        # @param receiver [Store::Objects::NamespaceObject]
        # @param method_object [Store::Objects::MethodObject]
        # @return [FunctionSignatures::Constructor, nil]
        def try_to_build_constructor(receiver, method_object)
          if method_object.path == 'Class#new' && receiver.kind == :meta_class && receiver.path != 'Class'
            base_class = registry.get(receiver.base_class_address)&.with_connection(registry: registry) || return
            initialize_object = FindMethod.new(registry).find(base_class, 'initialize')&.with_connection(registry: registry)
            Model::FunctionSignatures::Constructor.new(base_class, initialize_object)
          else
            nil
          end
        end

        # @param method_object [Store::Objects::MethodObject::Connected]
        def method_overloads(method_object)
          overloads = method_object.resolved_overloads
          resolve_delegate(method_object, overloads)
        end

        # @param method_object [Store::Objects::MethodObject::Connected]
        # @return [Array<FunctionSignatures::Overload>]
        def resolve_delegate(method_object, overloads)
          environment = Model::Environment.build(registry: registry)

          overloads.flat_map do |overload|
            if delegate_tag = overload.tag_list.find { |tag| tag.tag_name == 'delegate' }
              delegate_object = resolve_object(delegate_tag)
              delegate_object_overloads = delegate_object&.resolved_overloads || []
              found_overloads = delegate_object_overloads.flat_map do |overload|
                return_type = Model::FunctionSignatures::Overload.new(delegate_object, overload).rbs_type(environment).type.return_type
                signatures = environment.resolve_value_by_rbs_type(return_type).select_method(method_object.name, visibility: %i(public protected private))

                signatures.map do |signature|
                  Objects::Overload.new(
                    name: signature.name,
                    tag_list: signature.tags,
                    document: signature.document,
                    parameters: signature.parameters.raw_parameters,
                  )
                end
              end

              found_overloads.empty? ? [overload] : found_overloads
            else
              [overload]
            end
          end
        end

        # @param delegate_tag [Store::Objects::Tag::Connected]
        # @return [Store::Objects::Base::Connected, nil]
        def resolve_object(delegate_tag)
          return unless delegate_tag.name
          paths = Model::ScopedPath.new(delegate_tag.lexical_scope, delegate_tag.name).absolute_paths.map { |path| Address.of(path) }

          paths.each do |path|
            resolved = registry.get(path)&.with_connection(registry: registry)
            return resolved if resolved
          end

          nil
        end
      end
    end
  end
end
