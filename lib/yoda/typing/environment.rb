require 'set'

module Yoda
  module Typing
    class Environment
      def initialize
        @binds = {}
      end

      # @param key  [String, Symbol]
      def resolve(key)
        @binds[key.to_sym]
      end

      # @param key  [String, Symbol]
      # @param type [Symbol, Store::Types::Base]
      def bind(key, type)
        key = key.to_sym
        type = (type.is_a?(Symbol) && resolve(type)) || type
        @binds.transform_values! { |value| value == key ? type : value }
        @binds[key] = type
        self
      end

      class SendLog
        attr_reader :node, :return_type, :context
        # @param node        [::AST::Node]
        # @param return_type [Store::Types::Base]
        # @param context     [Context]
        def initialize(node, return_type, context)
          @node = node
          @return_type = return_type
          @context = context
        end
      end
    end
  end
end
