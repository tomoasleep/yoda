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
          # TODO
          node.children.slice(1..2).compact.reduce([unknown_type, env]) { |(_type, env), node| process(node, env) }
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
          process(node.children[1], env)
        when :resbody
          # TODO
          process(node.children[2], env)
        when :csend, :send
          process_send_node(node, env)
        when :block
          process_block_node(node, env)
        when :const
          [Store::Types::GenericType.new('::Module', const_name_of(node)), env]
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
      def process_send_node(node, env)
        receiver_node, method_name_sym, *argument_nodes = node.children
        if receiver_node
          receiver_type, env = process(receiver_node, env)
          class_candidates = context.find_class_candidates(receiver_type)
        else
          class_candidates = [context.caller_object]
        end
        _type, env = argument_nodes.reduce([unknown_type, env]) { |(_type, env), node| process(node.children.last, env) }
        method_candidates = context.find_instance_method_candidates(class_candidates, method_name_sym.to_s)
        method_return_type = context.calc_method_return_type(method_candidates)
        [method_return_type, env]
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      def process_block_node(node, env)
        send_node, arguments_node, body_node = node.children
        # TODO
        process(body_node, env)
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      def process_case_node(node, env)
        # TODO
        subject_node, *when_nodes, else_node = node.children
        _type, env = when_nodes.reduce([unknown_type, env]) { |(_type, env), node| process(node.children.last, env) }
        process(else_node, env)
      end

      # @param node [::AST::Node]
      # @param type [Store::Types::Base]
      # @param env  [Environment]
      def process_bind(symbol, type, env)
        [type, env.bind(symbol, type)]
      end

      # @param node [::AST::Node]
      def const_name_of(node)
        paths = []
        while true
          return '::' + paths.join('::') unless node
          return Store::Path.new(namespace, paths.join('::')) if node.type == :cbase
          paths.prepend(node.children[1])
          node = node.children[0]
        end
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
          Store::Types::ConstantType.new(sexp_type.to_s)
        when :int, :float, :complex, :rational
          Store::Types::InstanceType.new('::Numeric')
        else
          Store::Types::UnknownType.new(sexp_type)
        end
      end

      def boolean_type
        Store::Types::UnionType.new(Store::Types::ConstantType.new('true'), Store::Types::ConstantType.new('false'))
      end

      def unknown_type
        Store::Types::UnknownType.new
      end
    end
  end
end
