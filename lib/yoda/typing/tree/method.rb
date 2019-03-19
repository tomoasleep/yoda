module Yoda
  module Typing
    module Tree
      class Method < Base
        def name
          node.children.first
        end

        def argument
          @argument ||= build_child(node.children[1])
        end

        def body
          @body ||= node.children[2] && build_child(node.children[2], context: method_context)
        end

        # @return [Types::Base]
        def type
          @type ||= generator.symbol_type
        end

        def receiver_type
          @receiver_type ||= generator.union(context.current_objects.map { |object| generator.object_type(object) })
        end

        def method_context
          @method_context ||= method_definition_provider.generate_method_context(context: context, args_node: args_node)
        end

        private

        def method_definition_provider
          @method_definition_provider ||= MethodDefinitionResolver.new(
            receiver_type: receiver_type,
            name: name,
            registry: context.registry,
            generator: generator,
          )
        end
      end
    end
  end
end
