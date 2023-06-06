require 'forwardable'
require 'pp'

module Yoda
  module Typing
    module Tree
      # @abstract
      class Base
        extend Forwardable

        # @return [AST::Vnode]
        attr_reader :node

        # @return [Inferencer::Tracer]
        attr_reader :tracer

        # @return [Contexts::BaseContext]
        attr_reader :context

        delegate [:bind_tree, :bind_context, :bind_type, :bind_send, :bind_method_definition, :bind_require_paths, :bind_diagnostics] => :tracer

        # @return [Types::Generator]
        delegate [:generator] => :context

        # @param node [AST::Vnode]
        # @param tracer [Inferencer::Tracer]
        # @param context [Contexts::BaseContext]
        # @param parent [Base, nil]
        def initialize(node:, tracer:, context:, parent: nil)
          @node = node
          @tracer = tracer
          @context = context
          @parent = parent
        end

        # @return [Types::Type]
        def type
          @type ||= begin
            bind_tree(node: node, tree: self)
            bind_context(node: node, context: context)
            Logger.trace("Traversing #{node}")
            type = infer_type
            process_comment
            Logger.trace("Traversed #{node} -> #{type.to_s}")
            bind_type(node: node, type: type, context: context)

            type
          end
        end

        # @param context [Contexts::BaseContext]
        def process_comment(context: nil)
          @comment ||= begin
            comment = Comment.new(comment: node.comment_block, tracer: tracer, context: context || self.context)
            comment.process
            comment
          end
        end

        # @param node [AST::Vnode]
        # @return [Base]
        def build_child(node, context: self.context)
          Tree.build(node, context: context, tracer: tracer, parent: self)
        end

        # @param node [AST::Vnode]
        # @param (see #build_child)
        # @return [Types::Type]
        def infer_child(node, **kwargs)
          build_child(node, **kwargs).type
        end

        # @param pp [PP]
        def pretty_print(pp)
          pp.object_group(self) do
            pp.breakable
            pp.text "@node="
            pp.pp node
            pp.text "@context="
            pp.pp context
            pp.comma_breakable
            pp.text "@tracer="
            pp.pp tracer
          end
        end

        def inspect
          pretty_print_inspect
        end

        private

        # @abstract
        # @return [Types::Type]
        def infer_type
          fail NotImplementedError
        end
      end
    end
  end
end
