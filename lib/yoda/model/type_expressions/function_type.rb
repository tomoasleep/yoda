module Yoda
  module Model
    module TypeExpressions
      class FunctionType < Base
        require 'yoda/model/type_expressions/function_type/parameter'

        # @return [Base, nil]
        attr_reader :context

        # @return [Array<Parameter>]
        attr_reader :required_parameters, :optional_parameters, :post_parameters

        # @return [Array<Parameter>]
        attr_reader :required_keyword_parameters

        # @return [Array<Parameter>]
        attr_reader :optional_keyword_parameters

        # @return [Parameter, nil]
        attr_reader :rest_parameter, :keyword_rest_parameter, :block_parameter

        # @return [Base]
        attr_reader :return_type

        # @param context [Base, nil]
        # @param required_parameters [Array<Base>]
        # @param optional_parameters [Array<Base>]
        # @param rest_parameter [Base, nil]
        # @param post_parameters [Array<Base>]
        # @param required_keyword_parameters [Array<(String, Base)>]
        # @param optional_keyword_parameters [Array<(String, Base)>]
        # @param keyword_rest_parameter [Base, nil]
        # @param block_parameter [Base, nil]
        # @param return_type [Base]
        def initialize(context: nil, return_type:, required_parameters: [], optional_parameters: [], rest_parameter: nil, post_parameters: [], optional_keyword_parameters: [], required_keyword_parameters: [], keyword_rest_parameter: nil, block_parameter: nil)
          fail TypeError, return_type unless return_type.is_a?(Base)
          fail TypeError, context if context && !context.is_a?(Parameter)
          fail TypeError, rest_parameter if rest_parameter && !rest_parameter.is_a?(Parameter)
          fail TypeError, keyword_rest_parameter if keyword_rest_parameter && !keyword_rest_parameter.is_a?(Parameter)
          fail TypeError, block_parameter if block_parameter && !block_parameter.is_a?(Parameter)
          fail TypeError, required_parameters unless required_parameters.all? { |param| param.is_a?(Parameter) }
          fail TypeError, optional_parameters unless optional_parameters.all? { |param| param.is_a?(Parameter) }
          fail TypeError, post_parameters unless post_parameters.all? { |param| param.is_a?(Parameter) }
          fail TypeError, optional_keyword_parameters unless optional_keyword_parameters.all? { |param| param.is_a?(Parameter) }
          fail TypeError, required_keyword_parameters unless required_keyword_parameters.all? { |param| param.is_a?(Parameter) }

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

        # @param namespace [LexicalContext]
        # @return [FunctionType]
        def change_root(namespace)
          map { |type| type.change_root(namespace) }
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

        # @param env [Environment]
        # @return [RBS::Types::Function]
        def to_rbs_type(env)
          make_param = -> (param) { param&.to_rbs_param(env) }
          make_key_and_param = -> (param) { [param.name.to_sym, make_param.call(param)] }

          RBS::Types::Function.new(
            required_positionals: required_parameters.map(&make_param),
            optional_positionals: optional_parameters.map(&make_param),
            rest_positionals: make_param.call(rest_parameter),
            trailing_positionals: post_parameters.map(&make_param),
            # Not include keyword name to parameter object because if its string expression becomes redundunt.
            required_keywords: required_keyword_parameters.map(&make_key_and_param).to_h,
            optional_keywords: optional_keyword_parameters.map(&make_key_and_param).to_h,
            rest_keywords: make_param.call(keyword_rest_parameter),
            return_type: return_type&.to_rbs_type(env),
          )
        end

        # @return [self]
        def map(&block)
          call_map_type = -> (param) { param&.map_type(&block) }

          self.class.new(
            context: context&.map(&block),
            return_type: return_type.map(&block),
            required_parameters: required_parameters.map(&call_map_type),
            optional_parameters: optional_parameters.map(&call_map_type),
            rest_parameter: call_map_type.call(rest_parameter),
            post_parameters: post_parameters.map(&call_map_type),
            required_keyword_parameters: required_keyword_parameters.map(&call_map_type),
            optional_keyword_parameters: required_keyword_parameters.map(&call_map_type),
            keyword_rest_parameter: call_map_type.call(keyword_rest_parameter),
            block_parameter: call_map_type.call(block_parameter),
          )
        end

        private

        def all_parameters_to_s
          [
            *required_parameters.map(&:positional_expression),
            *optional_parameters.map(&:optional_expression),
            rest_parameter&.rest_expression,
            *post_parameters.map(&:positional_expression),
            *required_keyword_parameters.map(&:keyword_expression),
            *optional_keyword_parameters.map(&:optional_keyword_expression),
            keyword_rest_parameter&.keyword_rest_expression,
            block_parameter&.block_expression,
          ].compact.join(', ')
        end
      end
    end
  end
end
