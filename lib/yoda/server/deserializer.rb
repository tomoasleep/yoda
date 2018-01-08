require 'ostruct'

module Yoda
  class Server
    class Deserializer
      def initialize
      end

      # @param params [Hash]
      def deserialize(params)
        Hash[params.map { |key, value| [snakenize(key), deserialize_value(value)] }]
      end

      # @param params [any]
      def deserialize_value(value)
        return deserialize(value) if value.is_a?(Hash)
        return value.map { |el| deserialize_value(el) } if value.is_a?(Enumerable)
        value
      end

      # @param str [Symbol]
      def snakenize(str)
        str.to_s.gsub(/([A-Z])/, '_\1').downcase.to_sym
      end
    end
  end
end
