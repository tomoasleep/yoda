module Yoda
  module Typing
    # Does HM type inference
    class Inferencer
      class Context
        # @type Store::Registry
        attr_reader :registry

        # @type Store::Values::Base
        attr_reader :caller_object

        # @type Store::Values::Base
        attr_reader :namespace

        # @param registry      [Store::Registry]
        # @param caller_object [Store::Values::Base] represents who is self of the code.
        # @param namespace     [Store::Values::Base] represents where the code places.
        def initialize(registry, caller_object, namespace)
          fail ArgumentError, registry unless registry.is_a?(Store::Registry)
          fail ArgumentError, caller_object unless caller_object.is_a?(Store::Values::Base)

          @registry = registry
          @caller_object = caller_object
          @namespace = namespace
        end

        # @param name [String]
        # @return [Types::Base]
        def resolve_const_name(name)
        end
      end

      class Environment
        # @param context [Context]
        # @param parent [Environment, nil]
        def initialize(context, parent: nil)
          @context = context
          @parent = parent
          @binds = {}
        end

        # @param key  [String, Symbol]
        def resolve(key)
          @binds[key.to_sym]
        end

        # @param key  [String, Symbol]
        # @param type [Symbol, Store::Types::Base]
        def bind(key, type)
          key = key.to_sym
          type = (type.is_a?(Symbol) && resolve(type)) || type
          @binds.transform_values! { |value| value == key ? type : value }
          @binds[key] = type
          self
        end
      end

      # @type Context
      attr_reader :context

      # @type Environment
      attr_reader :env

      # @type Integer
      attr_reader :level

      # @param context [Context]
      def initialize(context, level: 0)
        @context = context
        @env = Environment.new(context)
        @level = level
      end

      # @param node [::AST::Node]
      # @return [Store::Types::Base]
      def infer(node)
        case node.type
        when :lvasgn, :ivasgn, :cvasgn, :gvasgn
          process_bind(node.children[0], node.children[1])
        when :casgn
          # TODO
          infer(node.children.last)
        when :masgn
          # TODO
          infer(node.children.last)
        when :op_asgn, :or_asgn, :and_asgn
          # TODO
          infer(node.children.last)
        when :and, :or, :not
          # TODO
          Types::Union.new(node.children.map { |node| infer(node) })
        when :if
          infer_branch_nodes(node.children.slice(1..2).compact)
        when :while, :until, :while_post, :until_post
          # TODO
          infer(node.children[1])
        when :for
          # TODO
          infer(node.children[2])
        when :case
          infer_case_node(node)
        when :super, :zsuper, :yield
          # TODO
          type_for_sexp_type(node.type)
        when :return, :break, :next
          # TODO
          node.children[0] ? infer(node.children[0]) : Types.nil_type
        when :resbody
          # TODO
          infer(node.children[2])
        when :csend, :send
          infer_send_node(node)
        when :block
          send_node, arg_node, block_node = node
          infer_send_node(send_node, arg_node, block_node)
        when :const
          infer_const_node(node)
        when :lvar, :cvar, :ivar, :gvar
          env.resolve(node.children.first) || unknown_type
        when :begin, :kwbegin, :block
          node.children.map { |node| infer(node) }.last
        when :dstr, :dsym, :xstr
          node.children.each { |node| infer(node, env) }
          type_for_sexp_type(node.type)
        else
          type_for_sexp_type(node.type)
        end
      end

      private

      # @param var [Symbol]
      # @param body_node [::AST::Node]
      # @return [Store::Types::Base]
      def process_bind(var, body_node)
        body_type = incremental_level {
          process(body_node)
        }
        generalized_type = generalize(body_type, level)
        env.bind(var, body_type)
        generalized_type
      end

      # Does process in incremented level.
      def incremental_level
        @level += 1
        result = yield
        @level -= 1
        result
      end

      # @param node [::AST::Node]
      # @return [Types::Base]
      def infer_const_node(node)
        context.resolve_const_name(Parsing::NodeObjects::ConstNode.new(node).to_s)
      end

      # @param node [::AST::Node]
      # @param block_param_node [::AST::Node, nil]
      # @param block_node [::AST::Node, nil]
      # @param env [Environment]
      # @return [Types::Base]
      def infer_send_node(node, block_param_node = nil, block_node = nil)
        method_type = infer_method_type

        argument_nodes = node.children.slice(2..-1)
        arguments = infer_argument_nodes(argument_nodes)

        if block_node
          block_return_type = Types::Var.new('block return')
          arguments[:block_arguments] = Types::Function.new(return_type: block_return_type)
        end

        return_type = Types::Var.new('method return')
        function_type = Types::Function.new(arguments, return_type: return_type)

        unify(method_type, function_type)
        if block_node
          # TODO
          unify(block_return_type, infer(block_node))
        end

        return_type
      end

      # @param node [::AST::Node]
      # @return [Types::Method]
      def infer_method_type(node, receiver_node)
        receiver_node, method_name_sym, *_argument_nodes = node.children
        receiver_type = receiver_node ? infer(receiver_node) : context.self_type
        Types::Method.new(receiver_type, method_name_sym.to_s)
      end

      # @param nodes [Array<::AST::Node>]
      # @return [{Symbol => Types::Base}]
      def infer_argument_nodes(nodes)
        argument_nodes.each_with_object({}) do |node, obj|
          case node.type
          when :splat
            # TODO
            infer(node)
          when :block_pass
            obj[:block_argument] = infer(node.children.first)
          else
            obj[:arguments] ||= []
            obj[:arguments].push(infer(node))
          end
        end
      end

      # @param node [Array<::AST::Node>]
      # @return [Types::Base]
      def infer_branch_nodes(nodes)
        Types::Union.new(nodes.map { |node| infer(node) })
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      # @return [[Store::Types::Base, Environment]]
      def infer_case_node(node)
        # TODO
        subject_node, *when_nodes, else_node = node.children
        when_body_nodes = when_nodes.map { |node| node.children.last }
        Types::Union.new([*when_body_nodes, else_node].map { |node| infer(node) })
      end

      # @param sexp_type [::Symbol, nil]
      def type_for_sexp_type(sexp_type)
        case sexp_type
        when :dstr, :str, :xstr, :string
          Types::Instance.new('::String')
        when :dsym, :sym
          Types::Instance.new('::Symbol')
        when :array, :splat
          Types::Instance.new('::Array')
        when :hash
          Types::Instance.new('::Hash')
        when :irange, :erange
          Types::Instance.new('::Range')
        when :regexp
          Types::Instance.new('::RegExp')
        when :defined
          Types.boolean_type
        when :self
          Types::Instance.new(context.caller_object.path)
        when :true
          Types.true_type
        when :false
          Types.false_type
        when :nil
          Types.nil_type
        when :int
          Types::Instance.new('::Integer')
        when :float
          Types::Instance.new('::Float')
        when :complex
          Types::Instance.new('::Numeric')
        when :rational
          Types::Instance.new('::Numeric')
        else
          Types.unknown_type
        end
      end
    end

    class Unifier
    end
  end
end
