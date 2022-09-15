module Yoda
  module Model
    module FunctionSignatures
      class Formatter
        # @return [FunctionSignatures::Base]
        attr_reader :signature

        # @param signature [FunctionSignatures::Base]
        def initialize(signature)
          @signature = signature
        end

        def to_s
          "#{signature.name}#{function_signature}"
        end

        private

        def function_signature
          params = all_parameters
          (params.empty? ? ': ' : "(#{params.join(', ')}): ") + "#{signature.type.return_type}"
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
          signature.parameters.required_parameters.map { |param| triple_to_s(param.name, type_of(param.name)) }
        end

        def optional_parameters
          signature.parameters.optional_parameters.map { |param| triple_to_s(param.name, type_of(param.name), param.default) }
        end

        def post_parameters
          signature.parameters.post_parameters.map { |param| triple_to_s(param.name, type_of(param.name)) }
        end

        def required_keyword_parameters
          signature.parameters.required_keyword_parameters.map { |param| "#{type_of(param.name)} #{param.name}:" }
        end

        def optional_keyword_parameters
          signature.parameters.required_keyword_parameters.map { |param| "#{type_of(param.name)} #{param.name}: #{param.default}" }
        end

        def rest_parameter
          signature.parameters.rest_parameter ? "#{type_of(signature.parameters.rest_parameter.name)} *#{signature.parameters.rest_parameter.name}" : nil
        end

        def keyword_rest_parameter
          signature.parameters.keyword_rest_parameter ? "#{type_of(signature.parameters.keyword_rest_parameter.name)} **#{signature.parameters.keyword_rest_parameter.name}" : nil
        end

        def block_parameter
          signature.parameters.block_parameter ? "#{type_of(signature.parameters.block_parameter.name)} **#{signature.parameters.block_parameter.name}" : nil
        end

        # @param name [String]
        # @param type [Base]
        # @param default_value [String, nil]
        def triple_to_s(name, type, default_value = nil)
          "#{type} #{name}" + (default_value ? " = #{ default_value }" : '')
        end

        def type_of(param)
          signature.parameter_type_of(param)
        end
      end
    end
  end
end
