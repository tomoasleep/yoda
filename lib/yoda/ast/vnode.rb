module Yoda
  module AST
    # @abstract
    class Vnode
      include NamespaceTraversable
      include MethodTraversable
      include Traversable

      # @return [Vnode, nil]
      attr_reader :parent

      # @param parent [Vnode, nil]
      def initialize(parent: nil)
        @parent = parent
      end

      # @return [Array<Vnode>] all nodes between root and self.
      def nesting
        @nesting ||= (parent&.nesting || []) + [self]
      end

      # @param [Parser::AST::Node]
      # @return [Vnode]
      def wrap_child(child_node)
        AST.wrap(child_node, parent: self)
      end

      # @return [Array<Vnode>]
      def children
        fail NotImplementedError
      end

      # @return [boolean]
      def empty?
        false
      end

      # @return [boolean]
      def present?
        !empty?
      end

      def constant?
        false
      end

      # @return [Symbol]
      def type
        fail NotImplementedError
      end

      # @return [String]
      def identifier
        "#{type}:#{object_id}"
      end

      # @return [String]
      def inspect
        "(#{[identifier, inspect_content].join(' ')})"
      end

      # @return [String]
      def inspect_content
        children.map(&:inspect).join(' ')
      end

      def try(method_name, *args)
        respond_to?(method_name) ? send(method_name, *args) : nil
      end
      
      module CommentAssociation
        # @param comments [Array<::Parser::Source::Comment>]
        # @return [Hash{Vnode => Array<Parser::Source::Comment>}]
        def associate_comments(comments)
          if node = try(:node)
            Parser::Source::Comment.associate(node, comments).map do |ast_key_node, comments|
              [all_nodes_lazy.find { |node| node.wrapping?(ast_key_node) }, comments]
            end.to_h
          else
            {}
          end
        end

        # @param node [::AST::Node]
        # @return [boolean]
        def wrapping?(node)
          try(:node) && try(:node) == node
        end

        # @return [Enumerable<Vnode>]
        def all_nodes_lazy
          [self, *children].lazy.flat_map { |el| self == el ? self : el.all_nodes_lazy }
        end
      end
      include CommentAssociation
      
      module Positional
        # @return [Parsing::Location, nil]
        def location
          source_map && Parsing::Location.of_ast_location(source_map)
        end
        
        # @return [Range, nil]
        def range
          source_map && Parsing::Range.of_ast_location(source_map)
        end
        
        # @return [Parser::Source::Map, nil]
        def source_map
          nil
        end

        # @param target [Parsing::Location, Parsing::Range, nil]
        # @return [boolean]
        def positionally_include?(target)
          range && range.include?(target)
        end

        # @param target [Location, Range, nil]
        # @return [Vnode]
        def positionally_nearest_child(target)
          if positionally_include?(target)
            children.find { |child| child.positionally_include?(target) }&.positionally_nearest_child(target) || self
          else
            nil
          end
        end
      end
      include Positional
    end
  end
end
