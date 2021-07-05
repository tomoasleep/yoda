module Yoda
  module Typing
    module Types
      class MethodCall < Base
        # @return [Base]
        attr_reader :receiver_type

        # @return [String]
        attr_reader :method_name

        # @return [Array<Base>]
        attr_reader :argument_types

        # @return [Boolean]
        attr_reader :implicit_receiver

        # @param callee [Base]
        # @param method_name [String]
        # @param implicit_receiver [true, false]
        def initialize(receiver_type, method_name, argument_types, implicit_receiver: false)
          @receiver_type = receiver_type
          @method_name = method_name
          @argument_types
          @implicit_receiver = implicit_receiver
        end

        def to_expression(resolver)
          callee_type = to_expression(callee)
          values = callee_type.instanciate(resolver.registry)
          Model::TypeExpressions::UnionType.new(
            values.map do |value|
              value.methods(visibility: visibility).select { |func| func.name == method_name }
            end.flatten
          )
        end

        def resolve
          # TODO: Support overloads
          method_candidates = receiver_type.value.select_method(node.selector_name, visibility: visibility)
          method_types = method_candidates.map(&:rbs_type)

          # if block_node
          #   # TODO: Resolve type variables by matching argument_types with arguments
          #   binds = ArgumentsBinder.new(generator: generator).bind(types: method_types, arguments: block_param_node.parameter)
          #   new_context = context.derive_block_context(binds: binds)
          #   derive(context: new_context).traverse(block_node)
          # end

          Logger.trace("method_candidates: [#{method_candidates.join(', ')}]")
          Logger.trace("receiver_type: #{receiver_type}")

          # bind_send(node: node, method_candidates: method_candidates, receiver_type: receiver_type)

          if method_types.empty?
            generator.unknown_type(reason: "method not found")
          else
            generator.union_type(*method_types.map { |method_type| method_type.type.return_type })
          end
        end

        def block_binder
          fail NotImplementedError
        end

        def visilibity
          implicit_receiver ? %i(private protected public) : %i(public)
        end

        def to_type_string
          "#{callee.to_type_string}##{method_name}"
        end
      end
    end
  end
end
