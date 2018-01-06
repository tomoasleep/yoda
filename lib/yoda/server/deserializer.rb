require 'ostruct'

module Yoda
  class Server
    class Deserilizer
      def initialize
      end

      # @param params [Hash]
      def deserialize(params)
        OpenStruct.new(params.transform_keys(&method(:snakenize)).transform_values(&method(:deserialize_value)))
      end

      # @param params [any]
      def deserialize_value(value)
        return deserialize(value) if value.is_a?(Hash)
        return value.map { |el| deserialize_value(el) } if value.is_a?(Enumerable)
        value
      end

      # @param str [String]
      def snakenize(str)
        str.gsub(/([A-Z])/, '_\1').downcase
      end
    end
  end
end
