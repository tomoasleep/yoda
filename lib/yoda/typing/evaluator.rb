module Yoda
  module Typing
    # Evaluator interpret codes abstractly and assumes types of terms.
    class Evaluator
      # @return [Context]
      attr_reader :context

      # @param context [Context]
      def initialize(context)
        @context = context
      end

      # @param node [::AST::Node]
      # @return [Model::Types::Base]
      def process(node)
        evaluate(node).tap { |type| bind_trace(node, Traces::Normal.new(context, type)) unless find_trace(node) }
      end

      # @param node  [::AST::Node]
      # @param trace [Trace::Base]
      def bind_trace(node, trace)
        context.bind_trace(node, trace)
      end

      # @param node  [::AST::Node]
      # @return [Trace::Base, nil]
      def find_trace(node)
        context.find_trace(node)
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
          if const = context.lexical_scope.find_constant(context.registry, const_node.to_s)
            Model::Types::ModuleType.new(const.path)
          else
            unknown_type
          end
        when :lvar, :cvar, :ivar, :gvar
          env.resolve(node.children.first) || unknown_type
        when :begin, :kwbegin, :block
          node.children.reduce(unknown_type) { |_type, node| process(node) }
        when :dstr, :dsym, :xstr
          node.children.map { |node| process(node) }
          type_for_sexp_type(node.type)
        when :def
          evaluate_method_definition(node)
        when :defs
          evaluate_smethod_definition(node)
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
          receiver_type = type_of_class(context.caller_object)
          receiver_candidates = [context.caller_object]
        end

        _type = argument_nodes.reduce([unknown_type]) { |(_type), node| process(node) }
        method_candidates = receiver_candidates.map { |receiver| Store::Query::FindSignature.new(context.registry).select(receiver, method_name_sym.to_s) }.flatten
        return_type = Model::Types::UnionType.new(method_candidates.map(&:type).map(&:return_type)).map do |type|
          type.is_a?(Model::Types::ValueType) && type.value == 'self' ? receiver_type : type
        end
        trace = Traces::Send.new(context, method_candidates, return_type)
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
          type_of_class(context.caller_object)
        when :true, :false, :nil
          Model::Types::ValueType.new(sexp_type.to_s)
        when :int, :float, :complex, :rational
          Model::Types::InstanceType.new('::Numeric')
        else
          Model::Types::UnknownType.new(sexp_type)
        end
      end

      # @param node [::AST::Node]
      # @return [Model::Types::Base]
      def evaluate_method_definition(node)
        new_caller_object = context.lexical_scope.namespace
        method_object = Store::Query::FindSignature.new(context.registry).select(new_caller_object, node.children[-3].to_s).first
        new_context = context.derive(caller_object: new_caller_object)
        new_context.env.bind_method_parameters(method_object)
        self.class.new(new_context).process(node.children[-1])
      end

      # @param node [::AST::Node]
      # @return [Model::Types::Base]
      def evaluate_smethod_definition(node)
        type = process(node.children[-4])
        new_caller_object = type.resolve(context.registry).first
        method_object = Store::Query::FindSignature.new(context.registry).select(new_caller_object, node.children[-3].to_s).first
        new_context = context.derive(caller_object: new_caller_object)
        if method_object
          new_context.env.bind_method_parameters(method_object)
        end
        self.class.new(new_context).process(node.children[-1])
      end

      # @param object [Store::Objects::Base]
      # @return [Model::Types::Base]
      def type_of_class(object)
        case object
        when Store::Objects::ClassObject, Store::Objects::ModuleObject
          Model::Types::InstanceType.new(object.path)
        when Store::Objects::MetaClassObject
          Model::Types::ModuleType.new(object.path)
        else
          Model::Types::UnknownType.new
        end
      end

      def boolean_type
        Model::Types::UnionType.new(Model::Types::ValueType.new('true'), Model::Types::ValueType.new('false'))
      end

      def unknown_type
        Model::Types::UnknownType.new
      end

      # @return [Environment]
      def env
        context.env
      end

      # @param node [Array<::AST::Node>]
      # @param env  [Environment]
      # @return [Array<Model::Values::Base>]
      def process_to_instanciate(node)
        type = evaluate(node)
        bind_trace(node, Traces::Normal.new(context, type)) unless find_trace(node)
        trace.values
      end
    end
  end
end
