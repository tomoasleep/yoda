require 'set'

module Yoda
  module Typing
    class Environment
      def initialize
        @binds = {}
      end

      def bind(key, value)
        @binds[key] = value
        self
      end

      def resolve(key)
        @binds[key]
      end

      # @param symbol [Symbol]
      # @param type   [Symbol, Store::Types::Base]
      def bind(key, type)
        type = (type.is_a?(Symbol) && resolve(type)) || type
        @binds.transform_values! { |value| value == key ? type : value }
        @binds[key] = type
        self
      end
    end
  end
end
