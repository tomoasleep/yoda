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
      # @param pattern [String, RegExp]
      def find_instance_method_candidates(objects, pattern)
        fail ArgumentError, objects unless objects.is_a?(Array)
        objects.reject { |klass| klass.type == :proxy }.map do |klass|
          klass&.meths.select { |meth| pattern.is_a?(String) ? meth.name.to_s.start_with?(pattern) : meth.name.to_s.match?(pattern) }
        end.flatten
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
