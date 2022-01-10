require 'forwardable'

module Yoda
  module Typing
    class ConstantResolver
      require 'yoda/typing/constant_resolver/cbase_query'
      require 'yoda/typing/constant_resolver/member_query'
      require 'yoda/typing/constant_resolver/node_tracer'
      require 'yoda/typing/constant_resolver/query'
      require 'yoda/typing/constant_resolver/relative_base_query'

      extend Forwardable

      # @return [Contexts::BaseContext]
      attr_reader :context

      # @return [Types::Generator]
      delegate [:generator] => :context

      # @param context [ContextsBaseContext]
      def initialize(context:)
        @context = context
      end

      # @param node [AST::ConstantNode]
      # @param tracer [Inferncer::Tracer]
      # @return [ConstantScope::Query]
      def build_query_for_node(node, tracer:)
        Query.from_node(node, tracer: tracer)
      end

      # @param node [AST::ConstantNode]
      # @param tracer [Inferncer::Tracer]
      # @return [Types::Base]
      def resolve_node(node, tracer:)
        query = Query.from_node(node, tracer: tracer)
        resolve(query)
      end

      # @param path [String]
      # @return [Types::Base]
      def resolve_path(path)
        query = Query.from_string(path.to_s)
        resolve(query)
      end

      # @param query [ConstantScope::Query]
      # @return [Types::Base]
      def resolve(query)
        query.tracer&.bind_context(context: context)
        type = infer(query)
        query.tracer&.bind_type(type: type, context: context)
        type
      end

      private

      def infer(query)
        case query.parent
        when CbaseQuery
          # Remember constant candidates
          constants = [context.environment.resolve_constant(query.name.to_s)].compact

          query.tracer&.bind_constants(constants: constants)

          generator.singleton_type_at("::#{query.name}")
        when RelativeBaseQuery
          lexical_values = context.lexical_scope_types.map(&:value)
          relative_path = query.name.to_s

          # Search nearest lexical scope first
          found_paths = lexical_values.reverse.reduce(nil) do |found_paths, value|
            found_paths || begin
              current_found_paths = value.select_constant_paths(relative_path)
              current_found_paths.empty? ? nil : current_found_paths
            end
          end

          if found_paths
            # Remember constant candidates
            constants = [context.environment.resolve_constant(found_paths.first)].compact

            query.tracer&.bind_constants(constants: constants)

            generator.singleton_type_at(found_paths.first)
          else
            generator.any_type
          end
        when MemberQuery
          base_type = resolve(query.parent)

          # Remember constant candidates
          paths = base_type.value.select_constant_paths(query.name.to_s)
          constants = paths.map { |path| context.environment.resolve_constant(path) }.compact

          query.tracer&.bind_constants(constants: constants)

          generator.wrap_rbs_type(base_type.value.select_constant_type(query.name.to_s))
        else
          fail "unexpected"
        end
      end
    end
  end
end
