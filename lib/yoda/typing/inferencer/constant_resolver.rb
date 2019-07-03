module Yoda
  module Typing
    class Inferencer
      # @deprecated
      class ConstantResolver
        # @retrn [Context]
        attr_reader :context

        # @return [AST::Node]
        attr_reader :node

        # @param context [Context]
        # @param node [AST::Node]
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

        # @return [Array<Model::Path>]
        def lexical_scopes
          @lexical_scopes ||= context.lexical_scope_objects.map(&:path)
        end

        # @return [Model::ScopedPath]
        def scoped_path
          scoped_path ||= Model::ScopedPath.new(lexical_scopes, node.path)
        end
      end
    end
  end
end
