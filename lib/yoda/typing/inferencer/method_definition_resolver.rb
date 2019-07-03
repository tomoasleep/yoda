module Yoda
  module Typing
    class Inferencer
      class MethodDefinitionResolver
        # @return [Store::Registry]
        attr_reader :registry

        # @return [Types::Base]
        attr_reader :receiver_type

        # @return [Symbol]
        attr_reader :name

        # @return [Types::Generator]
        attr_reader :generator

        # @param registry [Store::Registry]
        # @param receiver_type [Types::Base]
        # @param name [Symbol]
        # @param generator [Types::Generator]
        def initialize(registry:, receiver_type:, name:, generator:)
          @registry = registry
          @receiver_type = receiver_type
          @name = name
          @generator = generator
        end

        # Generate block context for the candidate
        # @param context [Context]
        # @param params_node [AST::ParametersNode]
        # @return [Context]
        def generate_method_context(context:, params_node:)
          binds = ArgumentsBinder.new(generator: generator).bind(types: method_types, arguments: params_node.parameter)

          MethodContext.new(parent: context, registry: registry, receiver: receiver_type, binds: binds)
        end

        # @return [Array<Types::Function>]
        def method_types
          @method_types ||= method_candidates.map(&:type).map { |type| converter.convert_from_expression(type) }
        end

        # @return [Array<FunctionSignatures::Base>]
        def method_candidates
          @method_candidates ||= receiver_candidates.map do |receiver|
            Store::Query::FindSignature.new(registry).select(receiver, name.to_s, visibility: %i(private protected public))
          end.flatten
        end

        # @return [Array<Store::Objects::NamespaceObject>]
        def receiver_candidates
          @receiver_candidates ||= ObjectResolver.new(registry: registry, generator: generator).call(receiver_type)
        end

        private

        # @return [Types::Converter]
        def converter
          @converter ||= generator.build_converter(self_type: receiver_type)
        end
      end
    end
  end
end
