module Yoda
  module Model
    module FunctionSignatures
      # TypeBuilder builds {TypeExpression::FunctionType} instance from YARD tags and parameter list.
      class TypeBuilder
        # @return [ParameterList]
        attr_reader :parameters

        # @return [Array<Store::Objects::Tag>]
        attr_reader :tag_list

        # @param parameters [ParameterList]
        # @param tag_list [Array<Store::Objects::Tag>]
        # @param lexical_scope [Array<Store::Objects::Tag>]
        def initialize(parameters, tag_list)
          @parameters = parameters
          @tag_list = tag_list
        end

        # @return [TypeExpressions::FunctionType]
        def type
          @type ||= begin
            if !type_tags.empty?
              parsed_type = parse_type_tag(type_tags.first)
              parsed_type.is_a?(TypeExpressions::FunctionType) ? parsed_type : TypeExpressions::FunctionType.new(return_type: parsed_type)
            else
              TypeExpressions::FunctionType.new(return_type: return_types.first || TypeExpressions::UnknownType.new('nodoc'), **parameter_options)
            end
          end
        end

        # @param param [String]
        # @return [TypeExpressions::Base]
        def type_of(param)
          param_type_table[param] || TypeExpressions::UnknownType.new('nodoc')
        end

        # @param param [ParameterList::Item]
        # @return [TypeExpressions::FunctionType::Parameter]
        def parameter_of(param)
          TypeExpressions::FunctionType::Parameter.new(name: param.name, type: type_of(param.name))
        end

        private

        # @param type_tag [Store::Objects::Tag]
        # @return [TypeExpressions::FunctionType]
        def parse_type_tag(tag)
          parsed_type = TypeParser.new(tag).type_of_type_tag
          parsed_type.is_a?(TypeExpressions::FunctionType) ? parsed_type : TypeExpressions::FunctionType.new(return_type: parsed_type)
        end

        # @return [Hash]
        def parameter_options
          @parameter_options ||= {
            required_parameters: parameters.required_parameters.map(&method(:parameter_of)),
            optional_parameters: parameters.optional_parameters.map(&method(:parameter_of)),
            rest_parameter: parameters.rest_parameter ? parameter_of(parameters.rest_parameter) : nil,
            post_parameters: parameters.post_parameters.map(&method(:parameter_of)),
            required_keyword_parameters: parameters.required_keyword_parameters.map(&method(:parameter_of)),
            optional_keyword_parameters: parameters.optional_keyword_parameters.map(&method(:parameter_of)),
            keyword_rest_parameter: parameters.keyword_rest_parameter ? parameter_of(parameters.keyword_rest_parameter) : nil,
            block_parameter: parameters.block_parameter ? parameter_of(parameters.block_parameter) : nil,
          }
        end

        # @return [Array<Store::Objects::Tag>]
        def return_tags
          @return_tag ||= tag_list.select { |tag| tag.tag_name == 'return' }
        end

        # @return [Array<Store::Objects::Tag>]
        def type_tags
          @type_tag ||= tag_list.select { |tag| tag.tag_name == 'type' }
        end

        # @return [Array<Store::Objects::Tag>]
        def param_tags
          @param_tags ||= tag_list.select { |tag| tag.tag_name == 'param' }
        end

        # @return [Array<TypeExpressions::Base>]
        def return_types
          @return_types ||= return_tags.map do |tag|
            TypeParser.new(tag).type
          end
        end

        # @return [{ String => TypeExpressions::Base }]
        def param_type_table
          @param_type_table ||= begin
            param_types = param_tags.map { |tag| TypeParser.new(tag).type }

            name_to_types = param_tags.map(&:name).zip(param_types).group_by(&:first)
            name_to_types.map { |k, v| [k, TypeExpressions::UnionType.new(v.map(&:last))] }.to_h
          end
        end

        class TypeParser
          attr_reader :tag

          # @param tag [Store::Objects::Tag]
          def initialize(tag)
            @tag = tag
          end

          # @return [TypeExpressions::Base]
          def type
            # yard tag may not have any type literals.
            if (tag.yard_types || []).empty?
              TypeExpressions::UnknownType.new('nodoc') 
            else
              TypeExpressions.from_tag(tag)
            end
          end

          # @return [TypeExpressions::Base]
          def type_of_type_tag
            Parsing::TypeParser.new.safe_parse(tag.text).change_root(convert_lexical_scope_literals(tag.lexical_scope))
          end

          private

          # @param lexical_scope_literals [Array<String>]
          # @param [Array<Path>]
          def convert_lexical_scope_literals(lexical_scope_literals)
            lexical_scope_literals.map { |literal| Path.new(literal) } + [Path.new('Object')]
          end
        end
      end
    end
  end
end
