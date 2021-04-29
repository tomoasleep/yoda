module Yoda
  module Typing
    module Types
      class Function < Base
        # @return [Base, nil]
        attr_reader :context

        # @return [Array<Base>]
        attr_reader :parameters

        # @return [Array<Base>]
        attr_reader :rest_parameter

        # @return [Array<Base>]
        attr_reader :post_parameters

        # @return [Array<(String, Base)>]
        attr_reader :keyword_parameters

        # @return [Base]
        attr_reader :keyword_rest_parameter

        # @return [(String, Base), nil]
        attr_reader :block_parameter

        # @return [Base]
        attr_reader :return_type

        # @param context [Base, nil]
        # @param parameters [Array<Base>]
        # @param rest_parameter [Base, nil]
        # @param post_parameters [Array<Base>]
        # @param keyword_parameters [Array<(String, Base)>]
        # @param keyword_rest_parameter [Base, nil]
        # @param block_parameter [Base, nil]
        # @param return_type [Base]
        def initialize(context: nil, return_type:, parameters: [], rest_parameter: nil, post_parameters: [], keyword_parameters: [], keyword_rest_parameter: nil, block_parameter: nil)
          @context = context
          @parameters = parameters
          @keyword_parameters = keyword_parameters
          @rest_parameter = rest_parameter
          @post_parameters = post_parameters
          @keyword_rest_parameter = keyword_rest_parameter
          @block_parameter = block_parameter
          @return_type = return_type
        end

        def to_expression
          Model::TypeExpressions::FunctionType.new(
            context: context.to_expression,
            return_type: return_type.to_expression,
            parameters: parameters.map(&:to_expression),
            rest_parameter: rest_parameter&.to_expression,
            post_parameters: post_parameters.map(&:to_expression),
            keyword_parameters: keyword_parameters.map { |keyword, type| [keyword, type.to_expression] },
            keyword_rest_parameter: keyword_rest_parameter&.to_expression,
            block_parameter: block_parameter&.to_expression,
          )
        end

        def to_type_string
          inspect
          # "#{context.to_type_string}()"
        end
      end
    end
  end
end
