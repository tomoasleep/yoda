module Yoda
  module Services
    class CodeCompletion
      class ConstProvider < BaseProvider
        # @return [true, false]
        def providable?
          !!current_ancestor_const_node
        end

        # Returns constant candidates by using the current lexical scope.
        # @return [Array<Model::CompletionItem>] constant candidates.
        def candidates
          const_candidates.map do |const_candidate|
            Model::CompletionItem.new(
              description: Model::Descriptions::ValueDescription.new(const_candidate),
              range: substitution_range,
              kind: complete_item_kind(const_candidate),
              prefix: just_after_separator? ? '::' : '',
            )
          end
        end

        private

        # @param object [Store::Objects::Base]
        # @return [Symbol]
        def complete_item_kind(object)
          case object.kind
          when :class
            :class
          when :module
            :module
          else
            :constant
          end
        end

        # @return [Range, nil]
        def substitution_range
          return nil unless providable?
          @substitution_range ||=
            if just_after_separator?
              Parsing::Range.of_ast_location(current_ancestor_const_node.node.location.double_colon)
            else
              Parsing::Range.of_ast_location(current_ancestor_const_node.node.location.name)
            end
        end

        # @return [Parsing::NodeObjects::ConstNode, nil]
        def current_ancestor_const_node
          @current_ancestor_const_node ||= begin
            node = source_analyzer.nodes_to_current_location_from_root.reverse.take_while { |el| [:const, :cbase].include?(el.type) }.last
            return nil if !node || node.type != :const
            Parsing::NodeObjects::ConstNode.new(node)
          end
        end

        # @return [Array<Store::Objects::Base>]
        def const_candidates
          return [] unless providable?
          return [] if const_parent_paths.empty?

          base_path = current_ancestor_const_node.to_path
          path = just_after_separator? ? Model::Path.from_names([base_path.spacename, '']) : base_path
          scoped_path = Model::ScopedPath.new(const_parent_paths, path)
          Store::Query::FindConstant.new(registry).select_with_prefix(scoped_path)
        end

        # @return [true, false]
        def just_after_separator?
          return @is_just_after_separator if instance_variable_defined?(:@is_just_after_separator)
          @is_just_after_separator = current_ancestor_const_node.just_after_separator?(source_analyzer.location)
        end

        # @return [Array<Store::Objects::Base>]
        def const_parent_paths
          @const_parent_paths ||= begin
            lexical_scope(source_analyzer.current_namespace)
          end
        end

        # @param namespace [Parsing::NodeObjects::Namespace]
        # @return [Array<Path>]
        def lexical_scope(namespace)
          namespace.paths_from_root.reverse.map { |name| Model::Path.build(name.empty? ? 'Object' : name.gsub(/\A::/, '')) }
        end
      end
    end
  end
end
