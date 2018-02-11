module Yoda
  module Model
    class FunctionSignature
      # @return [Store::Objects::MethodObject]
      attr_reader :method_object

      # @param method_object [Store::Objects::MethodObject]
      def initialize(method_object)
        @method_object = method_object
      end

      def to_s
        "#{method_object.name}#{function_signature}"
      end

      private

      def function_signature
        params = all_parameters
        (params.empty? ? ': ' : "(#{params.join(', ')}): ") + "#{method_object.type.return_type}"
      end

      def all_parameters
        [
          required_parameters,
          optional_parameters,
          rest_parameter,
          post_parameters,
          required_keyword_parameters,
          optional_keyword_parameters,
          keyword_rest_parameter,
          block_parameter
        ].flatten.compact
      end

      def required_parameters
        method_object.parameters.required_parameters.map { |param| triple_to_s(param, type_of(param)) }
      end

      def optional_parameters
        method_object.parameters.optional_parameters.map { |(param, value)| triple_to_s(param, type_of(param), value) }
      end

      def post_parameters
        method_object.parameters.post_parameters.map { |param| triple_to_s(param, type_of(param)) }
      end

      def required_keyword_parameters
        method_object.parameters.required_keyword_parameters.map { |param| "#{type_of(param)} #{param}:" }
      end

      def optional_keyword_parameters
        method_object.parameters.required_keyword_parameters.map { |(param, value)| "#{type_of(param)} #{param}: #{value}" }
      end

      def rest_parameter
        method_object.parameters.rest_parameter ? "#{type_of(method_object.parameters.rest_parameter)} *#{method_object.parameters.rest_parameter}"  : nil
      end

      def keyword_rest_parameter
        method_object.parameters.keyword_rest_parameter ? "#{type_of(method_object.parameters.keyword_rest_parameter)} **#{method_object.parameters.keyword_rest_parameter}"  : nil
      end

      def block_parameter
        method_object.parameters.block_parameter ? "#{type_of(method_object.parameters.block_parameter)} **#{method_object.parameters.block_parameter}"  : nil
      end

      # @param name [String]
      # @param type [Base]
      # @param default_value [String, nil]
      def triple_to_s(name, type, default_value = nil)
        "#{type} #{name}" + (default_value ? " = #{ default_value }" : '')
      end

      def type_of(param)
        method_object.parameter_type_of(param)
      end
    end
  end
end
