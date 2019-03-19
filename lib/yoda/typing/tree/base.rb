module Yoda
  module Typing
    module Tree
      # @abstract
      class Base
        # @return [::AST::Node]
        attr_reader :node

        # @return [BaseContext]
        attr_reader :context

        # @param node [::AST::Node]
        # @param context [BaseContext]
        # @param parent [Base, nil]
        def initialize(node:, context:, parent: nil)
          @node = node
          @context = context
          @parent = parent
        end

        # @abstract
        # @return [Array<Base>]
        def children
          fail NotImplementedError
        end

        # @abstract
        # @return [Types::Base]
        def type
          fail NotImplementedError
        end

        # @return [Types::Generator]
        def generator
          @generator ||= Types::Generator.new(context.registry)
        end

        # @param node [::AST::Node]
        # @return [Base]
        def build_child(node, context: nil)
          Tree.build(node, context: context, parent: self)
        end
      end
    end
  end
end
