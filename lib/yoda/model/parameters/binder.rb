module Yoda
  module Model
    module Parameters
      class Binder
        # @return [Base]
        attr_reader :parameter

        # @param parameter [Base]
        def initialize(parameter)
          @parameter = parameter
        end

        # @param type [Interface]
        # @param generator [Generator]
        # @return [Hash{ Symbol => Interface }]
        def bind(type:, generator:)
          BoundResult.new(type: type, parameter: parameter, generator: generator).type_bindings
        end

        # @abstract
        module TypeInterface
        end

        # @abstract
        module Generator
          def any_type; fail NotImplementedError; end
          def proc_type; fail NotImplementedError; end
          def hash_type; fail NotImplementedError; end
          def array_type; fail NotImplementedError; end
        end

        class BoundResult
          # @return [Interface]
          attr_reader :type

          # @return [Model::Parameters::Base]
          attr_reader :parameter

          # @return [Generator]
          attr_reader :generator

          # @param type [Interface]
          # @param parameter [Model::Parameters::Multiple] parameter
          # @param generator [Types::Generator]
          def initialize(type:, parameter:, generator:)
            @type = type
            @parameter = parameter
            @generator = generator
          end

          # @return [Hash{Symbol => Interface}]
          def type_bindings
            @type_bindings ||= {}
              .merge!(parameter_bindings)
              .merge!(keyword_parameter_bindings)
              .merge!(block_parameter)
          end

          # @return [Hash{Symbol => Interface}]
          def parameter_bindings
            @parameter_bindings ||= begin
              dict, parameters_remain, types_remain = bind_params_as_possible(parameter.parameters, type.parameters)
              # TODO: bind with rest paremter type
              dict = parameters_remain.reduce(dict) { |dict, param| dict.merge(bind_param(param, generator.any_type)) }

              postdict, post_parameters_remain, post_types_remain = bind_params_as_possible(parameter.post_parameters.reverse, type.post_parameters.reverse)
              dict = dict.merge(postdict)
              # TODO: bind with rest paremter type
              dict = post_parameters_remain.reduce(dict) { |dict, param| dict.merge(bind_param(param, generator.any_type)) }

              if parameter.rest_parameter
                if types_remain.empty? && post_types_remain.empty?
                  # TODO: bind rest things of keyword and block binding
                  dict = dict.merge(bind_param(parameter.rest_parameter, type.rest_parameter || generator.array_type))
                else
                  # TODO: bind as sequence type
                  dict = dict.merge(bind_param(parameter.rest_parameter, generator.array_type))
                end
              end

              dict
            end
          end

          # @return [Hash{Symbol => Interface}]
          def keyword_parameter_bindings
            @keyword_parameter_bindings ||= begin
              type_hash = type.keyword_parameters.to_h
              dict = parameter.keyword_parameters.reduce({}) do |dict, param|
                if name = (param.respond_to?(:name) && param.name)
                  dict.merge(name => type_hash.delete(param) || generator.any_type)
                else
                  dict
                end
              end

              if parameter.keyword_rest_parameter
                if type_hash.empty?
                  dict = dict.merge(bind_param(parameter.keyword_rest_parameter, type.keyword_rest_parameter || generator.hash_type))
                else
                  # TODO: merge
                  dict = dict.merge(bind_param(parameter.keyword_rest_parameter, generator.hash_type))
                end
              end

              dict
            end
          end

          # @return [Hash{Symbol => Interface}]
          def block_parameter
            @block_parameter ||= parameter.block_parameter ? bind_param(parameter.block_parameter, type.block_parameter || generator.proc_type) : {}
          end

          private

          # @param params [Array<Base>]
          # @param types [Array<Interface>]
          # @return [(Hash{Symbol => Interface}, Array<Symbol>, Array<Interface>)]
          def bind_params_as_possible(params, types)
            min_length = [params.length, types.length].min

            dict = params.take(min_length).zip(types.take(min_length)).reduce({}) do |memo, (param, type)|
              memo.merge(bind_param(param, type))
            end

            [dict, params.drop(min_length), types.drop(min_length)]
          end

          # @param param [Base]
          # @param type [Interface]
          # @return [Hash{Symbol => Interface}]
          def bind_param(param, type)
            case param.kind
            when :named
              { param.name => type }
            when :multiple
              # @todo
              {}
            else
              {}
            end
          end
        end
      end
    end
  end
end
