require 'set'

module Yoda
  module Store
    module Objects
      class ReferenceTag
        class << self
          def json_creatable?
            true
          end

          # @param params [Hash]
          def json_create(params)
            new(**params.map { |k, v| [k.to_sym, v] }.select { |(k, v)| %i(tag_name name reference_path lexical_scope).include?(k) }.to_h)
          end
        end

        # @return [String]
        attr_reader :tag_name

        # @return [String, nil]
        attr_reader :name

        # @return [String]
        attr_reader :reference_path

        # @return [Array<String>]
        attr_reader :lexical_scope

        # @param tag_name   [String]
        # @param name       [String, nil]
        # @param reference  [String, nil]
        # @param lexical_scope [Array<String>]
        def initialize(tag_name:, reference_path:, lexical_scope:, name: nil)
          @tag_name = tag_name
          @name = name
          @reference_path = reference_path
          @lexical_scope = lexical_scope
        end

        # @return [Hash]
        def to_h
          { name: name, tag_name: tag_name, reference_path: reference_path, lexical_scope: lexical_scope }
        end

        def hash
          ([self.kind] + to_h.to_a).hash
        end

        def kind
          :reference_tag
        end

        def eql?(another)
          another.respond_to?(:kind) && self.kind == another.kind && to_h == another.to_h
        end

        def ==(another)
          eql?(another)
        end

        # @return [Array<Address>]
        def reference_address_candidates
          Model::ScopedPath.new(lexical_scope, reference_path).absolute_paths.map { |path| Address.of(path) }
        end

        # @return [String]
        def to_json(_state = nil)
          to_h.merge(json_class: self.class.name).to_json
        end

        # @param (see ReferenceTag.new)
        # @return [Connected]
        def with_connection(**kwargs)
          self.class.const_get(:Connected).new(self, **kwargs)
        end

        class Resolver
          class CyclicError < StandardError; end

          class ResolveResult
            # @return [Array<Tag>]
            attr_reader :tags

            # @return [Array<Overload>]
            attr_reader :overloads

            # @param tags [Array<Tag>]
            # @param overloads [Array<Overload>]
            def initialize(tags:, overloads:)
              @tags = tags
              @overloads = overloads
            end
          end

          # @return [Registry::View]
          attr_reader :registry

          # @param registry [Registry::View]
          def initialize(registry)
            @registry = registry
          end

          # @param reference_tag [ReferenceTag::Connected]
          # @return [Array<Tag>]
          def resolve_tags(reference_tag)
            do_resolve(reference_tag).tags
          end

          # @param reference_tag [ReferenceTag::Connected]
          # @return [Array<Overload>]
          def resolve_overloads(reference_tag)
            do_resolve(reference_tag).overloads
          end

          private

          # @param reference_tag [ReferenceTag::Connected]
          # @param visited [Set<ReferenceTag>]
          # @return [ResolveResult]
          def do_resolve(reference_tag, visited = [])
            fail CyclicError, "#{reference_tag} has cyclic" if visited.include?(reference_tag)
            visited += [reference_tag]
            if object = reference_tag.referring_object
              nested_reference_results = object.ref_tag_list.map { |ref_tag| do_resolve_tags(ref_tag, visited) }

              referring_object_overloads = object.kind == :method ? object.overloads + nested_reference_results.flat_map(&:overloads) : []
              referring_object_tag_list = object.tag_list + nested_reference_results.flat_map(&:tags) + referring_object_overloads.flat_map(&:tags)

              ResolveResult.new(
                tags: filter_tags(reference_tag, object, referring_object_tag_list),
                overloads: filter_overloads(reference_tag, object, object.tag_list + nested_reference_results.flat_map(&:tags), referring_object_overloads),
              )
            else
              ResolveResult.new(
                tags: [],
                overloads: [],
              )
            end
          end

          # @param reference_tag [ReferenceTag::Connected]
          # @param object [Base::Connected]
          # @param tag_list [Array<Tag>]
          # @return [Array<Tag>]
          def filter_tags(reference_tag, object, tag_list)
            matched_tags = tag_list.select { |tag| match_tag?(reference_tag, tag) }
            normalize_referring_tags(reference_tag, object, matched_tags)
          end

          # @param reference_tag [ReferenceTag::Connected]
          # @param object [Base::Connected]
          # @param tag_list [Array<Tag>]
          # @return [Array<Tag>]
          # @param overloads [Array<Overload>]
          # @return [Array<Overload>]
          def filter_overloads(reference_tag, object, tag_list, overloads)
            if object.kind == :method && reference_tag.owner.kind == :method && reference_tag.tag_name.to_sym == :param
              if reference_tag.owner.parameters.forward_parameter && reference_tag.owner.parameters.items.length == 1
                method_interface = Overload.new(
                  name: object.name,
                  parameters: object.parameters.raw_parameters,
                  document: object.document,
                  tag_list: tag_list
                )

                return [method_interface] + overloads
              end
            end

            return []
          end

          # @param reference_tag [ReferenceTag]
          # @param tag [Tag]
          def match_tag?(reference_tag, tag)
            match_name = reference_tag.name ? tag.name == reference_tag.name : true

            if reference_tag.tag_name.to_sym == :param
              %i(param option).include?(tag.tag_name.to_sym)
            else
              tag.tag_name == reference_tag.tag_name
            end
          end

          # @param reference_tag [ReferenceTag::Connected]
          # @param object [Base::Connected]
          # @param matched_tags [Array<Tag>]
          # @return [Array<Tag>]
          def normalize_referring_tags(reference_tag, object, matched_tags)
            additional_tags = matched_tags.flat_map do |tag|
              if object.kind == :method && reference_tag.owner.kind == :method && (parameter_item = object.parameters.find_by_name(tag.name))
                normalized_rest_param_tags(reference_tag.owner, tag, parameter_item)
              else
                []
              end
            end

            matched_tags + additional_tags
          end

          # @param reference_tag_owner [MethodObject::Connected]
          # @param tag [Tag]
          # @param parameter_item [Model::FunctionSignatures::ParameterList::Item]
          # @return [Array<Tag>]
          def normalized_rest_param_tags(reference_tag_owner, tag, parameter_item)
            case tag.tag_name.to_sym
            when :param
              if (keyword_rest_parameter = reference_tag_owner.parameters.keyword_rest_parameter) && parameter_item.keyword?
                [
                  Tag.new(
                    tag_name: "option",
                    name: keyword_rest_parameter.name,
                    yard_types: tag.yard_types,
                    text: tag.text,
                    lexical_scope: tag.lexical_scope,
                    option_key: tag.name,
                    option_default: parameter_item.default,
                  ),
                ]
              else
                []
              end
            when :option
              if parameter_item.kind?(:keyword_rest)
                if keyword_parameter = reference_tag_owner.parameters.find_by_name(tag.option_key)
                  [
                    Tag.new(
                      tag_name: "param",
                      name: keyword_parameter.name,
                      yard_types: tag.yard_types,
                      text: tag.text,
                      lexical_scope: tag.lexical_scope,
                    ),
                  ]
                elsif keyword_rest_parameter = reference_tag.owner.keyword_rest_parameter
                  [
                    Tag.new(
                      tag_name: "option",
                      name: keyword_rest_parameter.name,
                      yard_types: tag.yard_types,
                      text: tag.text,
                      lexical_scope: tag.lexical_scope,
                      option_key: tag.option_key,
                      option_default: tag.option_default,
                    ),
                  ]
                else
                  []
                end
              else
                []
              end
            end
          end
        end

        # A wrapper class of {Objects::ReferenceTag} to allow access to registry.
        class Connected
          extend ConnectedDelegation

          delegate_to_object :tag_name,
                             :name,
                             :reference_path,
                             :reference_address_candidates,
                             :lexical_scope,
                             :kind,
                             :to_h,
                             :to_json,
                             :hash,
                             :eql?,
                             :==

          # @return [Base::Connected]
          attr_reader :owner

          # @return [ReferenceTag]
          attr_reader :object

          # @return [Registry]
          attr_reader :registry

          # @param object [ReferenceTag]
          # @param owner [Base::Connected]
          # @param registry [Registry]
          def initialize(object, registry:, owner:)
            @object = object
            @owner = owner
            @registry = registry
          end

          # @param (see ReferenceTag#with_connection)
          # @return [Connected]
          def with_connection(**kwargs)
            if kwargs == connection_options
              self
            else
              object.with_connection(**kwargs)
            end
          end

          # @return [Array<Tag>]
          def resolve_tags
            Resolver.new(registry).resolve_tags(self)
          end

          # @return [Array<Overload>]
          def resolve_overloads
            Resolver.new(registry).resolve_overloads(self)
          end

          # @return [Objects::Base, nil]
          def referring_object
            reference_address_candidates.each do |address|
              resolved = registry.get(address)&.with_connection(registry: registry)
              return resolved if resolved
            end

            nil
          end

          private

          # @return [Hash]
          def connection_options
            { owner: owner, registry: registry }
          end
        end
      end
    end
  end
end
