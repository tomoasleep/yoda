module Yoda
  module Typing
    module Types
      class LexicalConstant < Base
        # @return [Array<Base>]
        attr_reader :lexical_scope

        # @return [String]
        attr_reader :name

        # @param callee [Base]
        # @param method_name [String]
        def initialize(lexical_scope, method_name)
          @lexical_scope = lexical_scope
          @name = name
        end

        def resolve
          lexical_values = lexical_scope.types.map(&:value)

          # Search nearest lexical scope first
          found_paths = lexical_values.reverse.reduce(nil) do |found_paths, value|
            found_paths || begin
              current_found_paths = value.select_constant_paths(name)
              current_found_paths.empty? ? nil : current_found_paths
            end
          end

          if found_paths
            # Remember constant candidates
            constants = [context.environment.resolve_constant(found_paths.first)].compact
            tracer.bind_constants(node: node, constants: constants)
          
            generator.singleton_type_at(found_paths.first)
          else
            generator.any_type
          end
        end
      end
    end
  end
end
