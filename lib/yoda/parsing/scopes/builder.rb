module Yoda
  module Parsing
    module Scopes
      class Builder
        # @return [AST::Node]
        attr_reader :node

        # @param node [AST::Node]
        def initialize(node)
          @node = node
          @root_scope = Root.new(node)
        end

        # @return [Scope]
        def root_scope
          unless @did_build
            @did_build = true
            build(node, @root_scope)
          end
          @root_scope
        end

        # @param node [AST::Node]
        # @param scope [Base]
        # @return [void]
        def build(node, scope)
          return if !node || !node.is_a?(AST::Node)
          case node.type
          when :def
            mscope = MethodDefinition.new(node, scope)
            scope.method_definitions << mscope
            mscope.body_nodes.each { |node| build(node, mscope)}
          when :defs
            mscope = SingletonMethodDefinition.new(node, scope)
            scope.method_definitions << mscope
            mscope.body_nodes.each { |node| build(node, mscope)}
          when :class
            cscope = ClassDefinition.new(node, scope)
            scope.child_scopes << cscope
            cscope.body_nodes.each { |node| build(node, cscope)}
          when :sclass
            cscope = SingletonClassDefinition.new(node, scope)
            scope.child_scopes << cscope
            cscope.body_nodes.each { |node| build(node, cscope)}
          when :module
            mscope = ModuleDefinition.new(node, scope)
            scope.child_scopes << mscope
            mscope.body_nodes.each { |node| build(node, mscope)}
          when :begin, :kwbegin, :block
            node.children.each { |node| build(node, scope) }
          else
            if node.respond_to?(:children)
              node.children.map { |node| build(node, scope) }
            end
          end
        end
      end
    end
  end
end
