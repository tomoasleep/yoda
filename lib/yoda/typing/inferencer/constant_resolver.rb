module Yoda
  module Typing
    class Inferencer
      class ConstantResolver
        # @retrn [Context]
        attr_reader :context

        # @return [::AST::Node]
        attr_reader :node

        # @param context [Context]
        # @param node [::AST::Node]
        def initialize(context:, node:)
          @context = context
          @node = node
        end

        # @return [Types::Base]
        def resolve
          @resolved ||= Types::Union.new(*constants.map { generator.constant_type_from(constant) })
        end

        private

        # @return [Types::Generator]
        def generator
          @generator ||= Types::Generator.new(context.registry)
        end

        # @return [Store::Objects::Base]
        def constants
          @constants ||= Store::Query::FindConstant.new(registry).find(scoped_path)
        end

        # @return [Array<Path>]
        def lexical_scopes
          @lexical_scopes ||= namespaces.map(&:path)
        end

        # @return [ScopedPath]
        def scoped_path
          scoped_path ||= Model::ScopedPath.new(lexical_scopes.reverse, Parsing::NodeObjects::ConstNode.new(node).to_s)
        end

        # @return [Enumerator<NamespaceContext>]
        def namespaces
          Enumerator.new do |yielder|
            current_context = context
            while current_context
              yielder << current_context if current_context.is_a?(NamespaceContext)
              current_context = context.parent
            end
          end
        end
      end
    end
  end
end
