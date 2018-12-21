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

        # @return [Store::Objects::Base]
        def constant
          @constant ||= Store::Query::FindConstant.new(context.registry).find(scoped_path)
        end

        # @return [Types::Base]
        def resolve_constant_type
          case constant
          when Store::Objects::NamespaceObject
            generator.singleton_type_of(constant.path)
          when Store::Objects::ValueObject
            # TODO
            generator.any_type
          else
            generator.any_type
          end
        end

        private

        # @return [Types::Generator]
        def generator
          @generator ||= Types::Generator.new(context.registry)
        end

        # @return [Array<Path>]
        def lexical_scopes
          @lexical_scopes ||= context.lexical_scope_objects.map(&:path)
        end

        # @return [ScopedPath]
        def scoped_path
          scoped_path ||= Model::ScopedPath.new(lexical_scopes, const_node.to_s)
        end

        # @return [Parsing::NodeObjects::ConstNode]
        def const_node
          @const_node ||= Parsing::NodeObjects::ConstNode.new(node)
        end
      end
    end
  end
end
