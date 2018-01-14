require 'set'

module Yoda
  module Typing
    class Context
      attr_reader :registry, :caller_object, :namespace

      # @param registry      [Store::Registry]
      # @param caller_object [Store::Values::Base] represents who is the evaluator of the code.
      def initialize(registry, caller_object)
        fail ArgumentError, registry unless registry.is_a?(Store::Registry)
        fail ArgumentError, caller_object unless caller_object.is_a?(Store::Values::Base)

        @registry = registry
        @caller_object = caller_object
      end

      # @param type [Types::Base]
      # @return [Array<Store::Values::Base>]
      def instanciate(type)
        type.instanciate(registry)
      end

      # @param constant_name [String]
      # @return [Store::Path]
      def create_path(constant_name)
        # TODO
        Store::Path.new(caller_object.namespace, constant_name)
      end
    end
  end
end
