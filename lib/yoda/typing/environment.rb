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
      # @param type [Symbol, Model::Types::Base]
      def bind(key, type)
        key = key.to_sym
        type = (type.is_a?(Symbol) && resolve(type)) || type
        @binds.transform_values! { |value| value == key ? type : value }
        @binds[key] = type
        self
      end

      # @param signature [Model::FunctionSignatures::Base]
      # @return [self]
      def bind_method_parameters(signature)
        parameter_names = signature.parameters.parameter_names
        parameter_names.each do |name|
          bind(name.gsub(/:\Z/, ''), signature.parameter_type_of(name))
        end
      end
    end
  end
end
