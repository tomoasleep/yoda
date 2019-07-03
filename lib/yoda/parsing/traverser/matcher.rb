module Yoda
  module Parsing
    class Traverser
      class Matcher
        # @return [Symbol, nil]
        attr_reader :type

        # @return [Symbol, nil]
        attr_reader :name

        # @return [Proc, nil]
        attr_reader :predicate

        # @param type [Symbol, nil]
        # @param name [Symbol, nil]
        def initialize(type: nil, name: nil, &predicate)
          @type = type
          @name = name
          @predicate = predicate
        end

        # @param node [AST::Node]
        # @return [Boolean]
        def match?(node)
          return false if type && type != node.type
          return false if name && name != name_of(node)
          return false if predicate && !predicate.call(node)
          true
        end

        # @param node [AST::Node]
        # @return [Symbol, nil]
        # @see https://github.com/whitequark/parser/blob/v2.5.3.0/doc/AST_FORMAT.md
        def name_of(node)
          case node.type
          when :lvar, :ivar, :cvar, :gvar
            node.name
          when :lvasgn, :ivasgn, :cvasgn, :gvasgn
            node.assignee.try(:name)
          when :const
            node.name.name
          when :casgn
            node.assignee.name
          when :sym
            node.value
          when :send, :csend
            node.selector.name
          when :"op-asgn"
            node.children[1].name
          when :def
            node.name_clause.name
          when :defs
            node.name_clause.name
          when :arg, :blockarg, :kwarg
            node.content.try(:name)
          when :optarg, :kwoptarg
            node.content.try(:name)
          when :restarg, :kwrestarg
            node.content.try(:name)
          end
        end
      end
    end
  end
end
