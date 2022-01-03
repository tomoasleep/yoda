module Yoda
  module AST
    require 'yoda/ast/traversable'
    require 'yoda/ast/method_traversable'
    require 'yoda/ast/namespace_traversable'
    require 'yoda/ast/namespace'
    require 'yoda/ast/vnode'
    require 'yoda/ast/node'
    require 'yoda/ast/comment_block'

    require 'yoda/ast/array_node'
    require 'yoda/ast/assignment_node'
    require 'yoda/ast/block_call_node'
    require 'yoda/ast/block_node'
    require 'yoda/ast/case_node'
    require 'yoda/ast/center_operator_node'
    require 'yoda/ast/class_node'
    require 'yoda/ast/conditional_loop_node'
    require 'yoda/ast/constant_assignment_node'
    require 'yoda/ast/constant_node'
    require 'yoda/ast/def_node'
    require 'yoda/ast/def_singleton_node'
    require 'yoda/ast/empty_vnode'
    require 'yoda/ast/ensure_node'
    require 'yoda/ast/for_node'
    require 'yoda/ast/hash_node'
    require 'yoda/ast/if_node'
    require 'yoda/ast/interpolation_text_node'
    require 'yoda/ast/kwsplat_node'
    require 'yoda/ast/left_operator_node'
    require 'yoda/ast/literal_node'
    require 'yoda/ast/module_node'
    require 'yoda/ast/multiple_left_hand_side_node'
    require 'yoda/ast/name_vnode'
    require 'yoda/ast/optional_parameter_node'
    require 'yoda/ast/pair_node'
    require 'yoda/ast/parameter_node'
    require 'yoda/ast/parameters_node'
    require 'yoda/ast/rescue_node'
    require 'yoda/ast/rescue_clause_node'
    require 'yoda/ast/root_vnode'
    require 'yoda/ast/send_node'
    require 'yoda/ast/singleton_class_node'
    require 'yoda/ast/special_call_node'
    require 'yoda/ast/variable_node'
    require 'yoda/ast/when_node'

    class << self
      # @param node [::AST::Node]
      # @param parent [Vnode]
      # @param comment_by_node [Hash{Parser::AST::Node => Array<Parser::Source::Comment>}]
      # @return [Yoda::AST::Node]
      def wrap(node, parent: nil, comments_by_node: {})
        if parent
          wrapper_class_for(node).new(node, parent: parent, comments_by_node: comments_by_node)
        else
          RootVnode.new(node, comments_by_node: comments_by_node).content
        end
      end

      # @param node [::AST::Node]
      def wrapper_class_for(node)
        return EmptyVnode unless node
        return NameVnode if node.is_a?(Symbol)
        case node.type
        when :lvasgn, :ivasgn, :cvasgn, :gvasgn, :masgn, :op_asgn, :or_asgn, :and_asgn
          AssignmentNode
        when :casgn
          ConstantAssignmentNode
        when :not
          LeftOperatorNode
        when :and, :or
          CenterOperatorNode
        when :if
          IfNode
        when :case
          CaseNode
        when :const
          ConstantNode
        when :while, :until, :while_post, :until_post
          ConditionalLoopNode
        when :for
          ForNode
        when :super, :zsuper, :yield, :return, :break, :next, :self, :defined?, :redo, :undef
          SpecialCallNode
        when :ensure
          EnsureNode
        when :rescue
          RescueNode
        when :resbody
          RescueClauseNode
        when :csend, :send
          SendNode
        when :block
          BlockCallNode
        when :const
          ConstantNode
        when :lvar, :cvar, :ivar, :gvar
          VariableNode
        when :begin, :kwbegin, :block
          BlockNode
        when :dstr, :dsym, :xstr
          InterpolationTextNode
        when :args
          ParametersNode
        when :arg, :shadowarg, :restarg, :blockarg, :kwarg, :kwrestarg
          ParameterNode
        when :optarg, :kwoptarg
          OptionalParameterNode
        when :mlhs
          MultipleLeftHandSideNode
        when :def
          DefNode
        when :defs
          DefSingletonNode
        when :hash
          HashNode
        when :array
          ArrayNode
        when :pair
          PairNode
        when :module
          ModuleNode
        when :class
          ClassNode
        when :sclass
          SingletonClassNode
        when :kwsplat
          KwsplatNode
        when :int, :float, :complex, :rational, :str, :string, :sym
          LiteralNode
        else
          Node
        end
      end
    end
  end
end
