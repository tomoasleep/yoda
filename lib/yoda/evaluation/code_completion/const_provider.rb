module Yoda
  module Evaluation
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
            )
          end
        end

        private

        # @return [Range, nil]
        def substitution_range
          return nil unless providable?
          @substitution_range ||=
            if current_ancestor_const_node.just_after_separator?(source_analyzer.location)
              subst_location = Parsing::Location.of_ast_location(current_ancestor_const_node.node.location.double_colon.end)
              Parsing::Range.new(subst_location, subst_location)
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

        # @return [Array<Objects::Base>]
        def const_candidates
          return [] unless providable?
          return [] if const_parent_paths.empty?

          base_path = current_ancestor_const_node.to_path
          path = current_ancestor_const_node.just_after_separator?(source_analyzer.location) ? Model::Path.from_names([base_path.spacename, '']) : base_path
          scoped_path = Model::ScopedPath.new(const_parent_paths, path)
          Store::Query::FindConstant.new(registry).select_with_prefix(scoped_path)
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
