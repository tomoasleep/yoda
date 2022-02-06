module Yoda
  module Typing
    class Inferencer
      class ParameterBinder
        # @return [Base]
        attr_reader :parameter

        # @param parameter [Base]
        def initialize(parameter)
          @parameter = parameter
        end

        # @param type [RBS::MethodType]
        # @param generator [Types::Generator]
        # @param self_type [RBS::Types::t]
        # @return [TypeBinding]
        def bind(type:, generator:)
          method_type = generator.fresh_params_of_method_type(type)
          BoundResult.new(type: method_type, parameter: parameter, generator: generator).type_binding
        end

        class BoundResult
          # @return [RBS::MethodType]
          attr_reader :type

          # @return [Model::Parameters::Base]
          attr_reader :parameter

          # @return [Types::Generator]
          attr_reader :generator

          # @param type [RBS::MethodType]
          # @param parameter [Model::Parameters::Multiple] parameter
          # @param generator [Types::Generator]
          def initialize(type:, parameter:, generator:)
            @type = type
            @parameter = parameter
            @generator = generator
          end

          # @return [Hash{Symbol => Interface}]
          def type_binding
            @type_binding ||= begin
              bind = TypeBinding.new

              bind_positional_parameters(bind)
              bind_keyword_parameters(bind)
              bind_block_parameter(bind)

              bind
            end
          end

          private

          # @param bind [TypeBinding]
          def bind_positional_parameters(bind)
            # @example 
            #   (x, y, *extra, z)
            #   (string, integer, symbol, boolean, float)
            #   =>
            #   {x: string, y: integer, extra: [symbol, boolean], z: float}

            required_param_types = type.type.required_positionals.map(&:type).map(&method(:wrap_rbs_type))
            optional_param_types = type.type.optional_positionals.map(&:type).map(&method(:wrap_rbs_type))
            trailing_param_types = type.type.trailing_positionals.map(&:type).map(&method(:wrap_rbs_type))
            rest_param_type = type.type.rest_positionals&.type&.yield_self(&method(:wrap_rbs_type))

            pre_types = required_param_types + optional_param_types
            post_types = trailing_param_types

            pre_types_remained = bind_params(bind, params: parameter.parameters, types: pre_types)
            post_types_remained = bind_params(bind, params: parameter.post_parameters.reverse, types: post_types).reverse

            rest_type = begin
              if pre_types_remained.empty? && post_types_remained.empty?
                rest_param_type || generator.array_type
              else
                # TODO: Bind tuple
                generator.array_type
              end
            end

            if parameter.rest_parameter
              bind_param(bind, param: parameter.rest_parameter, type: rest_type)
            end
          end

          # @param bind [TypeBinding]
          def bind_keyword_parameters(bind)
            type_hash = type.type.required_keywords.merge(type.type.optional_keywords).map do |(symbol, param)|
              [symbol, wrap_rbs_type(param.type)]
            end.to_h

            parameter.keyword_parameters.each do |param|
              type = begin
                name = (param.respond_to?(:name) && param.name)
                (name && type_hash.delete(name)) || generator.any_type
              end

              bind_param(bind, param: param, type: type)
            end

            rest_type = begin
              if type_hash.empty?
                type.type.rest_keywords&.type&.yield_self(&method(:wrap_rbs_type)) || generator.hash_type
              else
                generator.hash_type
              end
            end

            if parameter.keyword_rest_parameter 
              bind_param(bind, param: parameter.keyword_rest_parameter, type: rest_type)
            end
          end

          # @param bind [TypeBinding]
          def bind_block_parameter(bind)
            block_type = type.block&.yield_self(&method(:wrap_rbs_type)) || generator.proc_type

            if parameter.block_parameter
              bind_param(bind, param: parameter.block_parameter, type: block_type)
            end
          end

          # @param bind [TypeBinding]
          # @param params [Array<Model::Parameters::Base>]
          # @param types [Array<Types::Type>]
          # @return [Array<Types::Type>] 
          def bind_params(bind, params:, types:)
            remained_params, remained_types = bind_params_as_possible(bind, params: params, types: types)

            # Bind untyped to all remained parameters
            remained_params.each { |param| bind_param(bind, param: param, type: generator.any_type) }

            remained_types
          end

          # @param bind [TypeBinding]
          # @param params [Array<Model::Parameters::Base>]
          # @param types [Array<Types::Type>]
          # @return [(Array<Symbol>, Array<Types::Type>)] 
          def bind_params_as_possible(bind, params:, types:)
            min_length = [params.length, types.length].min

            min_length.times do |i|
              bind_param(bind, param: params[i], type: types[i])
            end

            [params.drop(min_length), types.drop(min_length)]
          end

          # @param param [Model::Parameters::Base]
          # @param type [Types::Type]
          # @return [Hash{Symbol => Interface}]
          def bind_param(bind, param:, type:)
            case param.kind
            when :named
              bind.bind(param.name, type)
            when :multiple
              # @todo
              {}
            else
              {}
            end
          end

          def wrap_rbs_type(rbs_type)
            rbs_type = type.propage_context_to(rbs_type) if type.respond_to?(:act_as_type_wrapper?)
            generator.wrap_rbs_type(rbs_type)
          end
        end
      end
    end
  end
end
