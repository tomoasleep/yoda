module Yoda
  module Evaluation
    class CodeCompletion
      class ConstProvider < BaseProvider
        # @return [true, false]
        def providable?
          !!current_const
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

        # @return [Range]
        def substitution_range
          return nil unless current_const
          Parsing::Range.of_ast_location(current_const.node.location.name)
        end

        # @return [Parsing::NodeObjects::ConstNode, nil]
        def current_const
          @current_const ||= begin
            node = source_analyzer.nodes_to_current_location_from_root.reverse.take_while { |el| el.type == :const }.last
            return nil unless node
            Parsing::NodeObjects::ConstNode.new(node)
          end
        end

        # @return [Array<Objects::Base>]
        def const_candidates
          return [] unless providable?
          return [] if const_parent_paths.empty?
          scoped_path = Model::ScopedPath.new(const_parent_paths, current_const.to_s)
          Store::Query::FindConstant.new(registry).select_with_prefix(scoped_path)
        end

        # @return [Parsing::ConstNode]
        def const_parent
          current_const && current_const.parent_const
        end

        # @return [Array<Store::Objects::Base>]
        def const_parent_paths
          @const_parent_pathss ||= begin
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
