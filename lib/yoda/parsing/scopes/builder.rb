module Yoda
  module Parsing
    module Scopes
      class Builder
        # @return [AST::Node]
        attr_reader :node

        # @param node [AST::Node]
        def initailize(node)
          @node = node
          @root_scope = Root.new
        end

        # @param node [AST::Node]
        # @param scope [Base]
        def build(node, scope)
          case node.type
          when :lvasgn, :ivasgn, :cvasgn, :gvasgn
            evaluate_bind(node.children[0], process(node.children[1]))
          when :casgn
            # TODO
            process(node.children.last)
          when :masgn
            # TODO
            process(node.children.last)
          when :op_asgn, :or_asgn, :and_asgn
            # TODO
            process(node.children.last)
          when :and, :or, :not
            node.children.reduce(unknown_type) { |_type, node| process(node) }
          when :if
            evaluate_branch_nodes(node.children.slice(1..2).compact)
          when :while, :until, :while_post, :until_post
            # TODO
            process(node.children[1])
          when :for
            # TODO
            process(node.children[2])
          when :case
            evaluate_case_node(node)
          when :super, :zsuper, :yield
            # TODO
            type_for_sexp_type(node.type)
          when :return, :break, :next
            # TODO
            node.children[0] ? process(node.children[0]) : Model::Types::ValueType.new('nil')
          when :resbody
            # TODO
            process(node.children[2])
          when :csend, :send
            evaluate_send_node(node)
          when :block
            evaluate_block_node(node)
          when :const
            const_node = Parsing::NodeObjects::ConstNode.new(node)
            Model::Types::ModuleType.new(context.create_path(const_node.to_s))
          when :lvar, :cvar, :ivar, :gvar
            env.resolve(node.children.first) || unknown_type
          when :begin, :kwbegin, :block
            node.children.reduce(unknown_type) { |_type, node| process(node) }
          when :dstr, :dsym, :xstr
            node.children.map { |node| process(node) }
            type_for_sexp_type(node.type)
          end
        end
      end
    end
  end
end
