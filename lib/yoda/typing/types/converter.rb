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
              klass: is_class ? class_class : module_class,
              meta_klass: generator.find_or_build_meta_class(type_expression.path),
            )
          when Model::TypeExpressions::SequenceType
            # @todo Implement sequence type
            Instance.new(klass: generator.array_type)
          when Model::TypeExpressions::DuckType
            # @todo Implement duck type
            generator.any_type
          when Model::TypeExpressions::SelfType
            self_type || generator.any_type
          when Model::TypeExpressions::ValueType
            Instance.new(generator.find_or_build(type_expression.value_class))
          when Model::TypeExpressions::UnionType
            Union.new(*type_expression.types.map(&method(:convert_from_expression)))
          when Model::TypeExpressions::GenericType
            Generic.new(
              base: convert_from_expression(type_expression.base_type),
              type_args: type_expression.type_arguments.map(&method(:convert_from_expression)),
            )
          when Model::TypeExpressions::FunctionType
            Function.new(
              context: convert_from_expression(context),
              return_type: convert_from_expression(return_type),
              parameters: parameters.map(&method(:convert_from_expression)),
              rest_parameter: convert_from_expression(rest_parameter),
              post_parameters: post_parameters.map(&method(:convert_from_expression)),
              keyword_parameters: keyword_parameters.map { |keyword, type| [keyword, convert_from_expression(type)] },
              keyword_rest_parameter: keyword_rest_parameter && convert_from_expression(keyword_rest_parameter),
              block_parameter: block_parameter && convert_from_expression(block_parameter),
            )
          else
            fail ArgumentError, type_expression
          end
        end
      end
    end
  end
end
