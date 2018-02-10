require 'set'

module Yoda
  module Typing
    class Context
      # @return [Store::Registry]
      attr_reader :registry

      # @return [Store::Objects::Base]
      attr_reader :caller_object

      # @return [Array<Path>]
      attr_reader :lexical_scopes

      # @return [Environment]
      attr_reader :env

      # @param registry       [Store::Registry]
      # @param caller_object  [Store::Objects::Base] represents who is the evaluator of the code.
      # @param lexical_scopes [Array<Path>] represents where the code presents.
      def initialize(registry, caller_object, lexical_scopes)
        fail ArgumentError, registry unless registry.is_a?(Store::Registry)
        fail ArgumentError, caller_object unless caller_object.is_a?(Store::Objects::Base)
        fail ArgumentError, lexical_scopes unless lexical_scopes.is_a?(Array)

        @registry = registry
        @caller_object = caller_object
        @lexical_scopes = lexical_scopes
        @env = Environment.new
      end

      # @param constant_name [String]
      # @return [Model::ScopedPath]
      def create_path(constant_name)
        # TODO
        Model::ScopedPath.new(lexical_scopes, constant_name)
      end
    end
  end
end
