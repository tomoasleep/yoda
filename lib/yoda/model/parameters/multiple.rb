module Yoda
  module Model
    module Parameters
      class Multiple < Base
        # @return [Array<Base>]
        attr_reader :parameters, :post_parameters

        # @return [Array<Base>]
        attr_reader :keyword_parameters

        # @return [Base, nil]
        attr_reader :rest_parameter, :keyword_rest_parameter, :block_parameter, :forward_parameter

        # @param parameters [Array<Base>]
        # @param rest_parameter [Base, nil]
        # @param post_parameters [Array<Base>]
        # @param keyword_parameters [Array<(Base)>]
        # @param keyword_rest_parameter [Base, nil]
        # @param block_parameter [Base, nil]
        def initialize(parameters: [], rest_parameter: nil, post_parameters: [], keyword_parameters: [], keyword_rest_parameter: nil, block_parameter: nil, forward_parameter: nil)
          @parameters = parameters
          @keyword_parameters = keyword_parameters
          @rest_parameter = rest_parameter
          @post_parameters = post_parameters
          @keyword_rest_parameter = keyword_rest_parameter
          @block_parameter = block_parameter
          @forward_parameter = forward_parameter
        end

        # @return [Symbol]
        def kind
          :multiple
        end
      end
    end
  end
end
