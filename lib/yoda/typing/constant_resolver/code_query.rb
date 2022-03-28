require 'yoda/typing/constant_resolver/query'

module Yoda
  module Typing
    class ConstantResolver
      class CodeQuery < Query
        # @return [AST::Vnode]
        attr_reader :node

        # @return [Types::Type, nil]
        attr_accessor :result_type

        # @param node [AST::Vnode]
        def initialize(node:)
          @node = node
        end

        # @return [nil]
        def parent
          nil
        end
      end
    end
  end
end
