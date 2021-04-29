module Yoda
  module Typing
    module Types
      class Converter
        # @return [Generator]
        attr_reader :generator

        # @return [Types::Base, nil]
        attr_reader :self_type

        def initialize(generator, self_type: nil)
          @generator = generator
          @self_type = self_type
        end

        # @param type_expression [Model::TypeExpressions::Base]
        # @return [Base]
        def convert_from_expression(type_expression)
          case type_expression
          when Model::TypeExpressions::AnyType, Model::TypeExpressions::UnknownType
            Any.new
          when Model::TypeExpressions::InstanceType
            Instance.new(
              klass: generator.find_or_build(type_expression.path),
            )
          when Model::TypeExpressions::ModuleType
            is_class = %i(class meta_class).include?(generator.find(type_expression.path)&.kind)
            Instance.new(
              klass: generator.find_or_build_meta_class(type_expression.path),
            )
          when Model::TypeExpressions::SequenceType
            # @todo Implement sequence type
            generator.array_type
          when Model::TypeExpressions::DuckType
            # @todo Implement duck type
            generator.any_type
          when Model::TypeExpressions::SelfType
            self_type || generator.any_type
          when Model::TypeExpressions::ValueType
            value_class = type_expression.value_class
            value_class ? Instance.new(klass: generator.find_or_build(value_class)) : generator.any_type
          when Model::TypeExpressions::UnionType
            Union.new(*type_expression.types.map(&method(:convert_from_expression)))
          when Model::TypeExpressions::GenericType
            Generic.new(
              base: convert_from_expression(type_expression.base_type),
              type_args: type_expression.type_arguments.map(&method(:convert_from_expression)),
            )
          when Model::TypeExpressions::FunctionType
            Function.new(
              context: type_expression.context && convert_from_expression(type_expression.context),
              return_type: convert_from_expression(type_expression.return_type),
              parameters: type_expression.required_parameters.map(&method(:convert_from_expression)),
              rest_parameter: type_expression.rest_parameter && convert_from_expression(type_expression.rest_parameter),
              post_parameters: type_expression.post_parameters.map(&method(:convert_from_expression)),
              keyword_parameters: (type_expression.required_keyword_parameters + type_expression.optional_keyword_parameters).map { |keyword, type| [keyword, convert_from_expression(type)] },
              keyword_rest_parameter: type_expression.keyword_rest_parameter && convert_from_expression(type_expression.keyword_rest_parameter),
              block_parameter: type_expression.block_parameter && convert_from_expression(type_expression.block_parameter),
            )
          else
            fail ArgumentError, type_expression
          end
        end
      end
    end
  end
end
