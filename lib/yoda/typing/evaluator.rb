module Yoda
  module Typing
    # Evaluator interpret codes abstractly and assumes types of terms.
    class Evaluator
      attr_reader :context

      # @param context [Context]
      def initialize(context)
        @context = context
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      # @return [[Store::Types::Base, Environment]]
      def process(node, env)
        case node.type
        when :lvasgn, :ivasgn, :cvasgn, :gvasgn
          type, env = process(node.children[1], env)
          process_bind(node.children[0], type, env)
        when :casgn
          # TODO
          process(node.children.last, env)
        when :masgn
          # TODO
          process(node.children.last, env)
        when :op_asgn, :or_asgn, :and_asgn
          # TODO
          process(node.children.last, env)
        when :and, :or, :not
          # TODO
          node.children.reduce([unknown_type, env]) { |(_type, env), node| process(node, env) }
        when :if
          process_branch_nodes(node.children.slice(1..2).compact, env)
        when :while, :until, :while_post, :until_post
          # TODO
          process(node.children[1], env)
        when :for
          # TODO
          process(node.children[2], env)
        when :case
          process_case_node(node, env)
        when :super, :zsuper, :yield
          # TODO
          [type_for_sexp_type(node.type), env]
        when :return, :break, :next
          # TODO
          node.children[0] ? process(node.children[0], env) : [Store::Types::ValueType.new('nil'), env]
        when :resbody
          # TODO
          process(node.children[2], env)
        when :csend, :send
          process_send_node(node, env)
        when :block
          process_block_node(node, env)
        when :const
          [Store::Types::ModuleType.new(context.create_path(Parsing::NodeObjects::ConstNode.new(node).to_s)), env]
        when :lvar, :cvar, :ivar, :gvar
          [env.resolve(node.children.first) || unknown_type,  env]
        when :begin, :kwbegin, :block
          node.children.reduce([unknown_type, env]) { |(_type, env), node| process(node, env) }
        when :dstr, :dsym, :xstr
          _type, env = node.children.reduce([unknown_type, env]) { |(_type, env), node| process(node, env) }
          [type_for_sexp_type(node.type), env]
        else
          [type_for_sexp_type(node.type), env]
        end
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      # @return [[Array<Store::Values::Base>, env]]
      def process_to_instanciate(node, env)
        type, env = process(node, env)
        [context.instanciate(type), env]
      end

      # @param node [Array<::AST::Node>]
      # @param env  [Environment]
      # @return [[Store::Types::Base, Environment]]
      def process_branch_nodes(nodes, env)
        # TODO: Divide env
        types, env = nodes.reduce([[], env]) do |(types, env), node|
          type, env = process(node, env)
          [types + [type], env]
        end

        [Store::Types::UnionType.new(types), env]
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      # @return [[Store::Types::Base, Environment]]
      def process_send_node(node, env)
        receiver_node, method_name_sym, *argument_nodes = node.children
        if receiver_node
          receiver_candidates, env = process_to_instanciate(receiver_node, env)
        else
          receiver_candidates = [context.caller_object]
        end

        _type, env = argument_nodes.reduce([unknown_type, env]) { |(_type, env), node| process(node, env) }
        method_candidates = receiver_candidates.map(&:methods).flatten.select { |method| method.name.to_s == method_name_sym.to_s }
        method_return_type = Store::Types::UnionType.new(method_candidates.map(&:return_type))
        [method_return_type, env]
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      # @return [[Store::Types::Base, Environment]]
      def process_block_node(node, env)
        send_node, arguments_node, body_node = node.children
        # TODO
        _type, env = process(body_node, env)
        process(send_node, env)
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      # @return [[Store::Types::Base, Environment]]
      def process_case_node(node, env)
        # TODO
        subject_node, *when_nodes, else_node = node.children
        _type, env = when_nodes.reduce([unknown_type, env]) { |(_type, env), node| process(node.children.last, env) }
        process(else_node, env)
      end

      # @param node [::AST::Node]
      # @param type [Store::Types::Base]
      # @param env  [Environment]
      # @return [[Store::Types::Base, Environment]]
      def process_bind(symbol, type, env)
        [type, env.bind(symbol, type)]
      end

      # @param sexp_type [::Symbol, nil]
      def type_for_sexp_type(sexp_type)
        case sexp_type
        when :dstr, :str, :xstr, :string
          Store::Types::InstanceType.new('::String')
        when :dsym, :sym
          Store::Types::InstanceType.new('::Symbol')
        when :array, :splat
          Store::Types::InstanceType.new('::Array')
        when :hash
          Store::Types::InstanceType.new('::Hash')
        when :irange, :erange
          Store::Types::InstanceType.new('::Range')
        when :regexp
          Store::Types::InstanceType.new('::RegExp')
        when :defined
          boolean_type
        when :self
          Store::Types::InstanceType.new(context.caller_object.path)
        when :true, :false, :nil
          Store::Types::ValueType.new(sexp_type.to_s)
        when :int, :float, :complex, :rational
          Store::Types::InstanceType.new('::Numeric')
        else
          Store::Types::UnknownType.new(sexp_type)
        end
      end

      def boolean_type
        Store::Types::UnionType.new(Store::Types::ValueType.new('true'), Store::Types::ValueType.new('false'))
      end

      def unknown_type
        Store::Types::UnknownType.new
      end
    end
  end
end
