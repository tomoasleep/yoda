module Yoda
  module Store
    module Types
      class FunctionType < Base
        attr_reader :context, :parameters, :rest_parameter, :post_parameters, :keyword_parameters, :keyword_rest_parameter, :block_parameter, :return_type

        # @param context [Base, nil]
        # @param parameters [Array<(String, Base, String)>]
        # @param rest_parameter [(String, Base), nil]
        # @param post_parameters [Array<(String, Base)>]
        # @param keyword_parameters [Array<(String, Base, String)>]
        # @param keyword_rest_parameter [(String, Base), nil]
        # @param block_parameter [(String, Base), nil]
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

        def eql?(another)
          another.is_a?(FunctionType) &&
          context == another.context &&
          parameters == another.parameters &&
          keyword_parameters == another.keyword_parameters &&
          keyword_rest_parameter == another.keyword_rest_parameter &&
          rest_parameter == another.rest_parameter &&
          post_parameters == another.post_parameters &&
          block_parameter == another.block_parameter &&
          return_type == another.return_type
        end

        def hash
          [self.class.name, Set.new(types)].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [UnionType]
        def change_root(namespace)
          self.class.new(types.map { |type| type.change_root(namespace) })
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base, YARD::CodeObjects::Proxy>]
        def resolve(registry)
          types.map { |type| type.resolve(registry) }.flatten.compact
        end

        # @param registry [Registry]
        # @return [Array<Values::Base>]
        def instanciate(registry)
          types.map { |type| type.instanciate(registry) }.flatten
        end

        def method_type_signature
          params_str = all_parameters_to_s
          (params_str.empty? ? ': ' : "(#{params_str}): ") + "#{return_type}"
        end

        def to_s
          params_str = all_parameters_to_s
          (params_str.empty? ? '' : "(#{params_str}) -> ") + "#{return_type}"
        end

        private

        # @param name [String]
        # @param type [Base]
        # @param default_value [String, nil]
        def triple_to_s(name, type, default_value = nil)
          "#{type} #{name}" + (default_value ? " = #{ default_value }" : '')
        end

        def all_parameters_to_s
          strs = [parameters_to_s, rest_parameter_to_s, post_parameters_to_s, keyword_parameters_to_s, keyword_rest_parameter_to_s, block_parameter_to_s].reject { |str| str.empty? }
          strs.join(', ')
        end

        def parameters_to_s
          parameters.map { |(name, type, default_value)| triple_to_s(name, type, default_value) }.join(', ')
        end

        def keyword_parameters_to_s
          return '' if keyword_parameters.empty?
          "{ " + keyword_parameters.map { |(name, type, default_value)| triple_to_s(name, type, default_value) }.join(',') + " }"
        end

        def post_parameters_to_s
          post_parameters.map { |(name, type)| triple_to_s(name, type) }.join(', ')
        end

        def rest_parameter_to_s
          return '' unless rest_parameter
          name, type = rest_parameter
          "*" + triple_to_s(name, type)
        end

        def keyword_rest_parameter_to_s
          return '' unless keyword_rest_parameter
          name, type = keyword_rest_parameter
          "**" + triple_to_s(name, type)
        end

        def block_parameter_to_s
          return '' unless block_parameter
          name, type = block_parameter
          "&" + triple_to_s(name, type)
        end
      end
    end
  end
end
