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

          case current_ancestor_const_node.base.type
          when :cbase
            paths = evaluator.tracer.generator.object_class.value.select_constant_paths(constant_pattern)
          when :empty
            lexical_scope_types = evaluator.node_info(current_ancestor_const_node).lexical_scope_types
            paths = lexical_scope_types.flat_map do |type| 
              type.value.select_constant_paths(constant_pattern)
            end.uniq
          else
            node_info = evaluator.node_info(current_ancestor_const_node.base)
            paths = node_info.type.value.select_constant_paths(constant_pattern)
          end
            
          paths.map(&method(:resolve_constant)).compact
        end

        # @return [String, nil]
        def constant_prefix
          return nil unless providable?
          base_name = just_after_separator? ? '' : current_ancestor_const_node.name.name.to_s
        end

        # @return [Regexp]
        def constant_pattern
          return /\A\Z/ unless providable?
          /\A#{Regexp.escape(constant_prefix)}/
        end

        # @return [true, false]
        def just_after_separator?
          return @is_just_after_separator if instance_variable_defined?(:@is_just_after_separator)
          @is_just_after_separator = current_ancestor_const_node.just_after_separator?(location)
        end
        
        # @param path [Path, String]
        # @return [Store::Objects::Base, nil]
        def resolve_constant(path)
          environment.resolve_constant(path)
        end
      end
    end
  end
end
