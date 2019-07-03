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

        # @return [AST::Vnode, nil]
        def current_ancestor_const_node
          nearst_constant_group = ast.positionally_nearest_child(location)&.nesting&.reverse&.find(&:constant?)
        end

        # @return [Array<Store::Objects::Base>]
        def const_candidates
          return [] unless providable?

          if current_ancestor_const_node.base.present?
            namespace_path = evaluator.node_info(current_ancestor_const_node.base).objects.map(&:path).first
            return [] unless namespace_path
            base_name = just_after_separator? ? '' : current_ancestor_const_node.name.name.to_s
            path = Model::Path.from_names([namespace_path, base_name])
          else
            path = Model::ScopedPath.new(lexical_scopes, current_ancestor_const_node.path)
          end

          Store::Query::FindConstant.new(registry).select_with_prefix(path)
        end

        # @return [true, false]
        def just_after_separator?
          return @is_just_after_separator if instance_variable_defined?(:@is_just_after_separator)
          @is_just_after_separator = current_ancestor_const_node.just_after_separator?(location)
        end

        # @param namespace [Parsing::NodeObjects::Namespace]
        # @return [Array<Path>]
        def lexical_scopes
          evaluator.node_info(current_ancestor_const_node).scope_nestings.map(&:path)
        end
      end
    end
  end
end
