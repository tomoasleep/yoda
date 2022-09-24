module Yoda
  module Typing
    module Tree
      require 'yoda/typing/tree/base'

      require 'yoda/typing/tree/ask_defined'
      require 'yoda/typing/tree/begin'
      require 'yoda/typing/tree/block_call'
      require 'yoda/typing/tree/case'
      require 'yoda/typing/tree/class_tree'
      require 'yoda/typing/tree/comment'
      require 'yoda/typing/tree/conditional_loop'
      require 'yoda/typing/tree/constant_assignment'
      require 'yoda/typing/tree/constant'
      require 'yoda/typing/tree/ensure'
      require 'yoda/typing/tree/for'
      require 'yoda/typing/tree/hash_tree'
      require 'yoda/typing/tree/if'
      require 'yoda/typing/tree/interpolation_text'
      require 'yoda/typing/tree/literal_inferable'
      require 'yoda/typing/tree/literal'
      require 'yoda/typing/tree/local_exit'
      require 'yoda/typing/tree/logical_assignment'
      require 'yoda/typing/tree/logical_operator'
      require 'yoda/typing/tree/method_def'
      require 'yoda/typing/tree/method_inferable'
      require 'yoda/typing/tree/module_tree'
      require 'yoda/typing/tree/multiple_assignment'
      require 'yoda/typing/tree/namespace_inferable'
      require 'yoda/typing/tree/rescue_clause'
      require 'yoda/typing/tree/rescue'
      require 'yoda/typing/tree/self'
      require 'yoda/typing/tree/send'
      require 'yoda/typing/tree/singleton_class_tree'
      require 'yoda/typing/tree/singleton_method_def'
      require 'yoda/typing/tree/super'
      require 'yoda/typing/tree/variable_assignment'
      require 'yoda/typing/tree/variable'
      require 'yoda/typing/tree/yield'

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
            ConditionalLoop
          when :for
            For
          when :case
            Case
          when :super, :zsuper
            Super
          when :yield
            Yield
          when :return, :break, :next
            LocalExit
          when :ensure
            Ensure
          when :rescue
            Rescue
          when :resbody
            RescueClause
          when :csend, :send
            Send
          when :block
            BlockCall
          when :const
            Constant
          when :lvar, :cvar, :ivar, :gvar
            Variable
          when :begin, :kwbegin, :block
            Begin
          when :dstr, :dsym, :xstr
            InterpolationText
          when :def
            MethodDef
          when :defs
            SingletonMethodDef
          when :hash
            HashTree
          when :self
            Self
          when :defined?
            AskDefined
          when :class
            ClassTree
          when :module
            ModuleTree
          when :sclass
            SingletonClassTree
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
