module Yoda
  module Typing
    module Tree
      require 'yoda/typing/inferencer/arguments_binder'
      require 'yoda/typing/inferencer/contexts'
      require 'yoda/typing/inferencer/environment'
      require 'yoda/typing/inferencer/constant_resolver'
      require 'yoda/typing/inferencer/method_resolver'
      require 'yoda/typing/inferencer/method_definition_resolver'
      require 'yoda/typing/inferencer/object_resolver'
      require 'yoda/typing/inferencer/tracer'

      class << self
        # @param node [::AST::Node]
        # @return [Base]
        def build(node, **kwargs)
          klass_for_node(node).new(node: node, **kwargs)
        end

        # @param node [::AST::Node]
        # @return [class<Base>]
        def klass_for_node(node)
          case node.type
          when :lvasgn, :ivasgn, :cvasgn, :gvasgn
            VariableAssignment
          when :casgn
            ConstantAssignment
          when :masgn
            MultipleAssignment
          when :op_asgn, :or_asgn, :and_asgn
            LogicalAssignment
          when :and, :or, :not
            LogicalOperator
          when :if
            If
          when :while, :until, :while_post, :until_post
            While
          when :for
            For
          when :case
            Case
          when :super, :zsuper
            Super
          when :yield
            Yield
          when :return, :break, :next
            Escape
          when :resbody
            RescueBody
          when :csend, :send
            Send
          when :block
            Block
          when :const
            Const
          when :lvar, :cvar, :ivar, :gvar
            Variable
          when :begin, :kwbegin
            Begin
          when :dstr, :dsym, :xstr
            LiteralWithInterpolation
          when :def
            Method
          when :defs
            SingletonMethod
          when :hash
            HashBody
          when :self
            Self
          when :defined
            Defined
          when :module
            ModuleTree
          when :class
            ClassTree
          else
            Literal
          end
        end
      end

      private

      # @return [Types::Generator]
      def generator
        @generator ||= Types::Generator.new(context.registry)
      end

      # @param context [Context]
      # @return [self]
      def derive(context:)
        self.class.new(context: context, tracer: tracer)
      end
    end
  end
end
