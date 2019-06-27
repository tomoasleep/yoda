module Yoda
  module Typing
    class Inferencer
      require 'yoda/typing/inferencer/arguments_binder'
      require 'yoda/typing/inferencer/contexts'
      require 'yoda/typing/inferencer/environment'
      require 'yoda/typing/inferencer/constant_resolver'
      require 'yoda/typing/inferencer/method_resolver'
      require 'yoda/typing/inferencer/method_definition_resolver'
      require 'yoda/typing/inferencer/object_resolver'
      require 'yoda/typing/inferencer/tracer'

      # @return [BaseContext]
      attr_reader :context

      # @return [Tracer]
      attr_reader :tracer

      # @param context [BaseContext]
      # @param tracer [Tracer, nil]
      def initialize(context:, tracer: nil)
        @context = context
        @tracer = tracer || Tracer.new(registry: context.registry, generator: generator)
      end

      # @param node [::AST::Node]
      # @return [Store::Types::Base]
      def infer(node)
        tracer.bind_context(node: node, context: context)
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
          infer_branch_nodes(node.children.first, node.children.slice(1..2).compact)
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
          node.children[0] ? infer(node.children[0]) : generator.nil_type
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
          context.environment.resolve(node.children.first) || generator.any_type
        when :begin, :kwbegin, :block
          node.children.map { |node| infer(node) }.last
        when :dstr, :dsym, :xstr
          node.children.each { |node| infer(node) }
          type_for_sexp_type(node.type)
        when :def
          infer_method_node(node)
        when :defs
          infer_smethod_node(node)
        when :hash
          infer_hash_node(node)
        when :self
          context.receiver
        when :defined
          generator.boolean_type
        when :module, :class
          infer_namespace_node(node)
        else
          type_for_literal_sexp(node.type)
        end.tap { |type| tracer.bind_type(node: node, type: type, context: context) }
      end

      private

      # @param var [Symbol]
      # @param body_node [::AST::Node]
      # @return [Store::Types::Base]
      def process_bind(var, body_node)
        body_type = infer(body_node)
        context.environment.bind(var, body_type)
        body_type
      end

      # @param node [::AST::Node]
      # @return [Types::Base]
      def infer_const_node(node)
        constant_resolver = ConstantResolver.new(context: context, node: node)
        constant_resolver.resolve_constant_type
      end

      # @param node [::AST::Node]
      # @return [Types::Base]
      def infer_method_node(node)
        name, args_node, body_node = node.children
        receiver_type = generator.union(context.current_objects.map { |object| generator.object_type(object) })

        method_definition_provider = MethodDefinitionResolver.new(
          receiver_type: receiver_type,
          name: name,
          registry: context.registry,
          generator: generator,
        )

        if body_node
          method_context = method_definition_provider.generate_method_context(context: context, args_node: args_node)
          derive(context: method_context).infer(body_node)
        end

        generator.symbol_type
      end

      # @param node [::AST::Node]
      # @return [Types::Base]
      def infer_smethod_node(node)
        receiver_node, name, args_node, body_node = node.children
        receiver_type = infer(receiver_node)

        method_definition_provider = MethodDefinitionResolver.new(
          receiver_type: receiver_type,
          name: name,
          registry: context.registry,
          generator: generator,
        )

        if body_node
          method_context = method_definition_provider.generate_method_context(context: context, args_node: args_node)
          derive(context: method_context).infer(body_node)
        end

        generator.symbol_type
      end

      # @param node [::AST::Node]
      # @return [Types::Base]
      def infer_namespace_node(node)
        case node.type
        when :module
          name_node, block_node = node.children
        when :class
          name_node, _, block_node = node.children
        end
        constant_resolver = ConstantResolver.new(context: context, node: name_node)
        type = constant_resolver.resolve_constant_type
        block_context = NamespaceContext.new(objects: [constant_resolver.constant], parent: context, registry: context.registry, receiver: type)

        if block_node
          derive(context: block_context).infer(block_node)
        end

        type
      end

      # @param node [::AST::Node]
      # @return [Model::TypeExpressions::Base]
      def infer_hash_node(node)
        hash = node.children.each_with_object({}) do |node, memo|
          case node.type
          when :pair
            pair_key, pair_value = node.children
            case pair_key.type
            when :sym
              memo[pair_key.children.first.to_sym] = infer(pair_value)
            when :str
              memo[pair_key.children.first.to_s] = infer(pair_value)
            else
              # TODO: Support other key types.
            end
          when :kwsplat
            content_node = node.children.first
            content_type = infer(content_node)
            # TODO: merge infered result
          end
        end

        Types::AssociativeArray.new(contents: hash)
      end

      # @param node [::AST::Node]
      # @param block_param_node [::AST::Node, nil]
      # @param block_node [::AST::Node, nil]
      # @return [Types::Base]
      def infer_send_node(node, block_param_node = nil, block_node = nil)
        receiver_node, method_name_sym, *argument_nodes = node.children

        receiver_type = receiver_node ? infer(receiver_node) : context.receiver
        argument_types = infer_argument_nodes(argument_nodes)

        method_resolver = MethodResolver.new(
          registry: context.registry,
          receiver_type: receiver_type,
          name: method_name_sym.to_s,
          argument_types: argument_types,
          generator: generator,
          implicit_receiver: receiver_node.nil?,
        )

        if block_node
          new_context = method_resolver.generate_block_context(context: context, block_param_node: block_param_node)
          derive(context: new_context).infer(block_node)
        end

        tracer.bind_send(node: node, method_candidates: method_resolver.method_candidates, receiver_candidates: method_resolver.receiver_candidates)
        method_resolver.return_type
      end

      # @param nodes [Array<::AST::Node>]
      # @return [{Symbol => Types::Base}]
      def infer_argument_nodes(argument_nodes)
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

      # @param condition_node [::AST::Node]
      # @param branch_nodes [Array<::AST::Node>]
      # @return [Types::Base]
      def infer_branch_nodes(condition_node, branch_nodes)
        infer(condition_node)
        Types::Union.new(branch_nodes.map { |node| infer(node) })
      end

      # @param node [::AST::Node]
      # @return [[Store::Types::Base, Environment]]
      def infer_case_node(node)
        # TODO
        subject_node, *when_nodes, else_node = node.children
        when_body_nodes = when_nodes.map { |node| node.children.last }
        Types::Union.new([*when_body_nodes, else_node].compact.map { |node| infer(node) })
      end

      # @return [Types::Generator]
      def generator
        @generator ||= Types::Generator.new(context.registry)
      end

      # @param context [Context]
      # @return [self]
      def derive(context:)
        self.class.new(context: context, tracer: tracer)
      end

      # @param sexp_type [::Symbol, nil]
      # @return [Types::Base]
      def type_for_literal_sexp(sexp_type)
        case sexp_type
        when :dstr, :str, :xstr, :string
          generator.string_type
        when :dsym, :sym
          generator.symbol_type
        when :array, :splat
          generator.array_type
        when :hash
          generator.hash_type
        when :irange, :erange
          generator.range_type
        when :regexp
          generator.regexp_type
        when :true
          generator.true_type
        when :false
          generator.false_type
        when :nil
          generator.nil_type
        when :int
          generator.integer_type
        when :float
          generator.float_type
        when :complex
          generator.numeric_type
        when :rational
          generator.numeric_type
        else
          generator.any_type
        end
      end
    end
  end
end
