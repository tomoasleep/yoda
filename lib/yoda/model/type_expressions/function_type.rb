module Yoda
  module Model
    module TypeExpressions
      class FunctionType < Base
        # @return [Base, nil]
        attr_reader :context

        # @return [Array<Base>]
        attr_reader :required_parameters, :optional_parameters, :post_parameters

        # @return [Array<(String, Base)>]
        attr_reader :required_keyword_parameters

        # @return [Array<(String, Base)>]
        attr_reader :optional_keyword_parameters

        # @return [Base, nil]
        attr_reader :rest_parameter, :keyword_rest_parameter, :block_parameter

        # @return [Base]
        attr_reader :return_type

        # @param context [Base, nil]
        # @param required_parameters [Array<Base>]
        # @param optional_parameters [Array<Base>]
        # @param rest_parameter [Base, nil]
        # @param post_parameters [Array<Base>]
        # @param keyword_parameters [Array<(String, Base)>]
        # @param keyword_rest_parameter [Base, nil]
        # @param block_parameter [Base, nil]
        # @param return_type [Base]
        def initialize(context: nil, return_type:, required_parameters: [], optional_parameters: [], rest_parameter: nil, post_parameters: [], optional_keyword_parameters: [], required_keyword_parameters: [], keyword_rest_parameter: nil, block_parameter: nil)
          @context = context
          @required_parameters = required_parameters
          @optional_parameters = optional_parameters
          @required_keyword_parameters = required_keyword_parameters
          @optional_keyword_parameters = optional_keyword_parameters
          @rest_parameter = rest_parameter
          @post_parameters = post_parameters
          @keyword_rest_parameter = keyword_rest_parameter
          @block_parameter = block_parameter
          @return_type = return_type
        end

        def eql?(another)
          another.is_a?(FunctionType) &&
          context == another.context &&
          required_parameters == another.required_parameters &&
          optional_parameters == another.optional_parameters &&
          required_keyword_parameters.to_set == another.required_keyword_parameters.to_set &&
          optional_keyword_parameters.to_set == another.optional_keyword_parameters.to_set &&
          keyword_rest_parameter == another.keyword_rest_parameter &&
          rest_parameter == another.rest_parameter &&
          post_parameters == another.post_parameters &&
          block_parameter == another.block_parameter &&
          return_type == another.return_type
        end

        def hash
          [
            self.class.name,
            context,
            return_type,
            required_parameters,
            optional_parameters,
            rest_parameter,
            post_parameters,
            required_keyword_parameters,
            optional_keyword_parameters,
            keyword_rest_parameter,
            block_parameter,
          ].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [UnionType]
        def change_root(namespace)
          self.class.new(
            context: context&.change_root(namespace),
            return_type: return_type.change_root(namespace),
            required_parameters: required_parameters.map { |param| param.change_root(namespace) },
            optional_parameters: optional_parameters.map { |param| param.change_root(namespace) },
            rest_parameter: rest_parameter&.change_root(namespace),
            post_parameters: post_parameters.map { |param| param.change_root(namespace) },
            required_keyword_parameters: required_keyword_parameters.map { |name, param| [name, param.change_root(namespace)] },
            optional_keyword_parameters: required_keyword_parameters.map { |name, param| [name, param.change_root(namespace)] },
            keyword_rest_parameter: keyword_rest_parameter&.change_root(namespace),
            block_parameter: block_parameter&.change_root(namespace),
          )
        end

        # @param registry [Registry]
        # @return [Array<Store::Objects::Base>]
        def resolve(registry)
          []
        end

        def method_type_signature
          params_str = all_parameters_to_s
          (params_str.empty? ? ': ' : "(#{params_str}): ") + "#{return_type}"
        end

        def to_s
          params_str = all_parameters_to_s
          (params_str.empty? ? '' : "(#{params_str}) -> ") + "#{return_type}"
        end

        # @return [self]
        def map(&block)
          self.class.new(
            context: context&.map(&block),
            return_type: return_type.map(&block),
            required_parameters: required_parameters.map { |param| param.map(&block) },
            optional_parameters: optional_parameters.map { |param| param.map(&block) },
            rest_parameter: rest_parameter&.map(&block),
            post_parameters: post_parameters.map { |param| param.map(&block) },
            required_keyword_parameters: required_keyword_parameters.map { |name, param| [name, param.map(&block)] },
            optional_keyword_parameters: required_keyword_parameters.map { |name, param| [name, param.map(&block)] },
            keyword_rest_parameter: keyword_rest_parameter&.map(&block),
            block_parameter: block_parameter&.map(&block),
          )
        end

        private

        def all_parameters_to_s
          [
            required_parameters_to_s,
            optional_parameters_to_s,
            rest_parameter_to_s,
            post_parameters_to_s,
            keyword_parameters_to_s,
            keyword_rest_parameter_to_s,
            block_parameter_to_s
          ].reject { |str| str.empty? }.join(', ')
        end

        def required_parameters_to_s
          required_parameters.map { |type| type.to_s }.join(', ')
        end

        def optional_parameters_to_s
          optional_parameters.map { |type| "?#{type}" }.join(', ')
        end

        def required_keyword_parameters_to_s
          return '' if required_keyword_parameters.empty?
          required_keyword_parameters.map { |(name, type)| "#{name}: #{type}" }.join(', ')
        end

        def optional_keyword_parameters_to_s
          return '' if optional_keyword_parameters.empty?
          optional_keyword_parameters.map { |(name, type)| "?#{name}: #{type}" }.join(', ')
        end

        def post_parameters_to_s
          post_parameters.map { |type| type.to_s }.join(', ')
        end

        def rest_parameter_to_s
          rest_parameter ? "*#{rest_parameter}" : ''
        end

        def keyword_rest_parameter_to_s
          keyword_rest_parameter ? "**#{keyword_rest_parameter}" : ''
        end

        def block_parameter_to_s
          block_parameter ? "&#{block_parameter}" : ''
        end
      end
    end
  end
end
