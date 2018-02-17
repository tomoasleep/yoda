module Yoda
  module Typing
    # Evaluator interpret codes abstractly and assumes types of terms.
    class Evaluator
      # @return [Context]
      attr_reader :context

      # @param context [Context]
      def initialize(context)
        @context = context
        @traces = {}
      end

      # @param node [::AST::Node]
      # @return [Model::Types::Base]
      def process(node)
        evaluate(node).tap { |type| bind_trace(node, Traces::Normal.new(context, type)) unless find_trace(node) }
      end

      # @param node  [::AST::Node]
      # @return [Trace::Base, nil]
      def find_trace(node)
        @traces[node]
      end

      private

      # @param node [::AST::Node]
      # @return [Model::Types::Base]
      def evaluate(node)
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
          # TODO
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
        else
          type_for_sexp_type(node.type)
        end
      end

      # @param node [Array<::AST::Node>]
      # @return [Model::Types::Base]
      def evaluate_branch_nodes(nodes)
        Model::Types::UnionType.new(nodes.map { |node| process(node) })
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      # @return [Model::Types::Base]
      def evaluate_send_node(node)
        receiver_node, method_name_sym, *argument_nodes = node.children
        if receiver_node
          receiver_type = process(receiver_node)
          receiver_candidates = receiver_type.resolve(context.registry)
        else
          receiver_candidates = [context.caller_object]
        end

        _type = argument_nodes.reduce([unknown_type]) { |(_type), node| process(node) }
        method_candidates = receiver_candidates.map { |receiver| Store::Query::FindSignature.new(context.registry).select(receiver, method_name_sym.to_s) }.flatten
        trace = Traces::Send.new(context, method_candidates)
        bind_trace(node, trace)
        trace.type
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      # @return [[Model::Types::Baseironment]]
      def evaluate_block_node(node)
        send_node, arguments_node, body_node = node.children
        # TODO
        _type = process(body_node)
        process(send_node)
      end

      # @param node [::AST::Node]
      # @param env  [Environment]
      # @return [[Model::Types::Baseironment]]
      def evaluate_case_node(node)
        # TODO
        subject_node, *when_nodes, else_node = node.children
        _type = when_nodes.reduce([unknown_type]) { |(_type), node| process(node.children.last) }
        process(else_node)
      end

      # @param node [::AST::Node]
      # @param type [Model::Types::Base]
      # @param env  [Environment]
      # @return [Model::Types::Base]
      def evaluate_bind(symbol, type)
        env.bind(symbol, type)
        type
      end

      # @param sexp_type [::Symbol, nil]
      def type_for_sexp_type(sexp_type)
        case sexp_type
        when :dstr, :str, :xstr, :string
          Model::Types::InstanceType.new('::String')
        when :dsym, :sym
          Model::Types::InstanceType.new('::Symbol')
        when :array, :splat
          Model::Types::InstanceType.new('::Array')
        when :hash
          Model::Types::InstanceType.new('::Hash')
        when :irange, :erange
          Model::Types::InstanceType.new('::Range')
        when :regexp
          Model::Types::InstanceType.new('::RegExp')
        when :defined
          boolean_type
        when :self
          Model::Types::InstanceType.new(context.caller_object.path)
        when :true, :false, :nil
          Model::Types::ValueType.new(sexp_type.to_s)
        when :int, :float, :complex, :rational
          Model::Types::InstanceType.new('::Numeric')
        else
          Model::Types::UnknownType.new(sexp_type)
        end
      end

      def boolean_type
        Model::Types::UnionType.new(Model::Types::ValueType.new('true'), Model::Types::ValueType.new('false'))
      end

      def unknown_type
        Model::Types::UnknownType.new
      end

      # @param node  [::AST::Node]
      # @param trace [Trace::Base]
      def bind_trace(node, trace)
        @traces[node] = trace
      end

      # @return [Environment]
      def env
        context.env
      end

      # @param node [Array<::AST::Node>]
      # @param env  [Environment]
      # @return [Array<Model::Values::Base>]
      def process_to_instanciate(node)
        r = evaluate(node)
        trace = lift(r)
        bind_trace(node, trace)
        trace.values
      end
    end
  end
end
