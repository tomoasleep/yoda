require_relative 'base'

module Yoda
  module Typing
    module Diagnostics
      class MethodNotFound < Base
        # @return [AST::Node]
        attr_reader :node

        # @return [Types::Type]
        attr_reader :receiver_type

        # @return [Symbol]
        attr_reader :method_name

        # @param receiver_type [Types::Type]
        # @param method_name [Symbol]
        def initialize(node:, receiver_type:, method_name:)
          @node = node
          @receiver_type = receiver_type
          @method_name = method_name
        end

        def message
          "`#{method_name}` method is not found in `#{receiver_type}` type"
        end

        # @return [Parsing::Range]
        def range
          node.is_a?(AST::SendNode) ? node.range_without_arguments : node.range
        end
      end
    end
  end
end
