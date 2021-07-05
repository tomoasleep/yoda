module Yoda
  module Typing
    module Types
      class ConstantAccess < Base
        # @return [Base]
        attr_reader :namespace

        # @return [String]
        attr_reader :name

        # @param namespace [Base]
        # @param name [String]
        def initialize(namespace, name)
          @namespace = namespace
          @name = name
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
          # Remember constant candidates
          paths = namespace.value.select_constant_paths(name)
          constants = paths.map { |path| context.environment.resolve_constant(path) }.compact
          # tracer.bind_constants(node: node, constants: constants)

          generator.wrap_rbs_type(namespace.value.select_constant_type(name))
        end

        def to_type_string
          "#{callee.to_type_string}##{method_name}"
        end
      end
    end
  end
end
