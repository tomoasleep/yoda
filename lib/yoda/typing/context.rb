require 'set'

module Yoda
  module Typing
    class Context
      attr_reader :registry, :caller_object, :namespace

      # @param registry      [Store::Registry]
      # @param caller_object [YARD::CodeObjects::Base] represents who is the evaluator of the code.
      # @param namespace     [YARD::CodeObjects::Base] represents the namespace where the code is written.
      def initialize(registry, caller_object, namespace)
        @registry = registry
        @caller_object = caller_object
        @namespace = namespace
      end

      # @param objects [Array<YARD::CodeObjects::Base, YARD::CodeObjects::Proxy>]
      # @param name    [String, RegExp]
      def find_instance_method_candidates(objects, name)
        fail ArgumentError, objects unless objects.is_a? Array
        return [] if name.is_a?(String) && name.empty?
        objects.reject { |klass| klass.type == :proxy }.map { |klass| klass&.meths.select { |meth| meth.name.match?(name) } }.flatten
      end

      def calc_method_return_type(methods)
        Store::Types::UnionType.new(methods.map { |method| Store::Function.new(method).return_type })
      end

      # @return [Array<YARD::CodeObjects::Base, YARD::CodeObjects::Proxy>]
      def find_class_candidates(type)
        type.resolve(registry)
      end
    end
  end
end
