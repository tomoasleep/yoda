module Yoda
  module Typing
    class Inferencer
      class MethodResolver
        # @return [Store::Registry]
        attr_reader :registry

        # @return [Types::Base]
        attr_reader :receiver_type

        # @return [Array<Types::Base>]
        attr_reader :argument_types

        # @return [String]
        attr_reader :name

        # @return [Types::Generator]
        attr_reader :generator

        # @param registry [Store::Registry]
        # @param receiver_type [Types::Base]
        # @param argument_type[Array<Types::Base>]
        # @param name [String]
        # @param name [Types::Generator]
        def initialize(registry:, receiver_type:, argument_types:, name:, generator:)
          @registry = registry
          @receiver_type = receiver_type
          @argument_type = argument_types
          @name = name
          @generator = generator
        end

        # Generate block context for the candidate
        # @param context [Context]
        # @param block_param_node [::AST::Node]
        # @return [Context]
        def generate_block_context(context:, block_param_node:)
          args_node = Parsing::NodeObjects::ArgsNode.new(block_param_node)
          argument_types = receiver_candidates
          binds = ArgumentsBinder.new(generator: generator).bind(types: method_types, arguments: args_node.parameter)

          BlockContext.new(parent: context, registry: registry, receiver: context.receiver, binds: binds)
        end

        # @return [Types::Base]
        def return_type
          @return_type ||= begin
            Types::Union.new(*method_candidates.map(&:type).map(&:return_type).map { |type| converter.convert_from_expression(type) })
          end
        end

        # @return [Array<Types::Function>]
        def method_types
          @method_types ||= method_candidates.map(&:type).map { |type| converter.convert_from_expression(type) }
        end

        # @return [Array<FunctionSignatures::Base>]
        def method_candidates
          @method_candidates ||=
            Store::Query::FindSignature.new(registry)
                                       .select_on_multiple(receiver_candidates, name.to_s, visibility: implicit_receiver ? %i(private protected public) : %i(public))
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
