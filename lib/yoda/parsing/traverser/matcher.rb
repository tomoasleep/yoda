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

        # @param node [::AST::Node]
        # @return [Boolean]
        def match?(node)
          return false if type && type != node.type
          return false if name && name != name_of(node)
          return false if predicate && !predicate.call(node)
          true
        end

        # @param node [::AST::Node]
        # @return [Symbol, nil]
        # @see https://github.com/whitequark/parser/blob/v2.5.3.0/doc/AST_FORMAT.md
        def name_of(node)
          case node.type
          when :lvar, :ivar, :cvar, :gvar
            node.children.first
          when :lvasgn, :ivasgn, :cvasgn, :gvasgn
            node.children.first
          when :const
            node.children.last
          when :casgn
            node.children[1]
          when :sym
            node.children.first
          when :send, :csend
            node.children[1]
          when :"op-asgn"
            node.children[1]
          when :def
            node.children.first
          when :defs
            node.children[1]
          when :arg, :blockarg, :kwarg
            node.children.first
          when :optarg, :kwoptarg
            node.children.first
          when :restarg, :kwrestarg
            node.children.first
          end
        end
      end
    end
  end
end
