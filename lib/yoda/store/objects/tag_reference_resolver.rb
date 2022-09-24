require 'set'

module Yoda
  module Store
    module Objects
      class TagReferenceResolver
        class CyclicError < StandardError; end

        class ResolveResult
          # @return [Array<Tag::Connected>]
          attr_reader :tags

          # @return [Array<Overload>]
          attr_reader :overloads

          # @param tags [Array<Tag>]
          # @param overloads [Array<Overload>]
          def initialize(tags:, overloads:)
            fail ArgumentError, tags if tags.any? { |tag| tag.nil? }
            @tags = tags
            @overloads = overloads
          end

          # @param results [Array<ResolveResult>]
          # @return [ResolveResult]
          def self.join(results)
            ResolveResult.new(
              tags: results.flat_map(&:tags),
              overloads: results.flat_map(&:overloads),
            )
          end
        end

        class Tagging
          # @return [Tag::Connected]
          attr_reader :tag

          # @return [Base::Connected]
          attr_reader :owner

          # @param tag [Tag::Connected]
          # @param owner [Base::Connected]
          def initialize(tag:, owner:)
            @tag = tag
            @owner = owner
          end
        end

        # @return [Registry::View]
        attr_reader :registry

        # @param registry [Registry::View]
        def initialize(registry)
          @registry = registry
        end

        # @param object [Base::Connected]
        # @return [Array<Tag>]
        def resolve_tags(object)
          resolve_for_object(object).tags
        end

        # @param object [Base::Connected]
        # @return [Array<Overload>]
        def resolve_overloads(object)
          resolve_for_object(object).overloads
        end

        private

        # @param object [Base::Connected]
        # @param visited [Set<Object>]
        # @return [ResolveResult]
        def resolve_for_object(object, visited = [])
          results[object] ||= begin
            fail CyclicError, "#{reference_tag} has cyclic" if visited.include?(object)
            visited += [object]

            results = object.tag_list.map { |tag| resolve_for_tagging(Tagging.new(tag: tag, owner: object), visited) }
            joined_result = ResolveResult.join(results)

            if object.kind == :method
              original_self_overload = object.self_overload
              self_overload = Overload.new(
                name: original_self_overload.name,
                parameters: original_self_overload.parameters.raw_parameters,
                document: original_self_overload.document,
                tag_list: joined_result.tags.map(&:object),
              )

              overload_result = ResolveResult.new(
                tags: [], 
                overloads: [self_overload] + object.overloads,
              )

              ResolveResult.join([joined_result, overload_result])
            else
              joined_result
            end
          end
        end

        # @param tagging [Tagging]
        # @param visited [Set<Object>]
        # @return [ResolveResult]
        def resolve_for_tagging(tagging, visited = [])
          if referring_object = tagging.tag.referring_object
            result = resolve_for_object(referring_object, visited)

            ResolveResult.new(
              tags: filter_tags(tagging, result.tags.map { |tag| Tagging.new(tag: tag, owner: referring_object) }),
              overloads: filter_overloads(tagging, referring_object, result.overloads),
            )
          else
            ResolveResult.new(
              tags: [tagging.tag],
              overloads: [],
            )
          end
        end

        # @param reference_tagging [Tagging]
        # @param referring_object_taggings [Array<Tagging>]
        # @return [Array<Tag>]
        def filter_tags(reference_tagging, referring_object_taggings)
          matched_taggings = referring_object_taggings.select { |object_tagging| match_tag?(reference_tagging, object_tagging) }

          additional_tags = matched_taggings.flat_map do |tagging|
            if reference_tagging.owner.kind == :method && tagging.owner.kind == :method
              additional_rest_param_tags(reference_tagging, tagging)
            else
              []
            end
          end

          matched_taggings.map(&:tag) + additional_tags
        end

        # @param reference_tagging [Tagging]
        # @param referring_object [Base::Connected]
        # @param overloads [Array<Overload>]
        # @return [Array<Overload>]
        def filter_overloads(reference_tagging, referring_object, overloads)
          if reference_tagging.owner.kind == :method && referring_object.kind == :method && reference_tagging.tag.tag_name.to_sym == :param
            if reference_tagging.owner.parameters.forward_parameter && reference_tagging.owner.parameters.items.length == 1
              return overloads.map do |overload|
                Overload.new(
                  name: reference_tagging.owner.name,
                  parameters: overload.parameters.raw_parameters,
                  document: overload.document,
                  tag_list: overload.tag_list,
                )
              end
            end
          end

          return []
        end

        # @param reference_tagging [Tagging]
        # @param tagging [Tagging]
        def match_tag?(reference_tagging, tagging)
          match_name = reference_tagging.tag.name ? tagging.tag.name == reference_tag.name : true

          if reference_tagging.tag.tag_name.to_sym == :param
            %i(param option).include?(tagging.tag.tag_name.to_sym)
          else
            tagging.tag.tag_name == reference_tagging.tag.tag_name
          end
        end

        # @param reference_tagging [Tagging]
        # @param tagging [Tagging]
        # @return [Array<Tag>]
        def additional_rest_param_tags(reference_tagging, tagging)
          case reference_tagging.tag.tag_name.to_sym
          when :param
            parameter_item = tagging.owner.parameters.find_by_name(tagging.tag.name)
            return [] unless parameter_item&.keyword?

            if keyword_rest_parameter = reference_tagging.owner.parameters.keyword_rest_parameter
              [
                Tag.new(
                  tag_name: "option",
                  name: keyword_rest_parameter.name,
                  yard_types: tagging.tag.yard_types,
                  text: tagging.tag.text,
                  lexical_scope: tagging.tag.lexical_scope,
                  option_key: tagging.tag.name,
                  option_default: parameter_item.default,
                ).with_connection(registry: registry),
              ]
            else
              []
            end
          when :option
            if parameter_item.kind?(:keyword_rest)
              if keyword_parameter = reference_tagging.owner.parameters.find_by_name(tag.option_key)
                [
                  Tag.new(
                    tag_name: "param",
                    name: keyword_parameter.name,
                    yard_types: tagging.tag.yard_types,
                    text: tagging.tag.text,
                    lexical_scope: tagging.tag.lexical_scope,
                  ).with_connection(registry: registry),
                ]
              elsif keyword_rest_parameter = reference_tagging.owner.keyword_rest_parameter
                [
                  Tag.new(
                    tag_name: "option",
                    name: keyword_rest_parameter.name,
                    yard_types: tagging.tag.yard_types,
                    text: tagging.tag.text,
                    lexical_scope: tagging.tag.lexical_scope,
                    option_key: tagging.tag.option_key,
                    option_default: tagging.tag.option_default,
                  ).with_connection(registry: registry),
                ]
              else
                []
              end
            else
              []
            end
          else
            []
          end
        end

        # @return [Hash{Object => ResolveResult}]
        def results
          @results ||= {}
        end
      end
    end
  end
end
