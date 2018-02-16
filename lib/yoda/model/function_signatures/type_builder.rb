module Yoda
  module Model
    module FunctionSignatures
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

        # @return [Types::FunctionType]
        def type
          @type ||= begin
            if !type_tags.empty?
              parsed_type = parse_type_tag(type_tags.first)
              parsed_type.is_a?(Types::FunctionType) ? parsed_type : Types::FunctionType.new(return_type: parsed_type)
            else
              Types::FunctionType.new(return_type: return_types.first || Types::UnknownType.new('nodoc'), **parameter_options)
            end
          end
        end

        # @param param [String]
        # @return [Types::Base]
        def type_of(param)
          param_type_table[param] || Types::UnknownType.new('nodoc')
        end

        private

        # @param type_tag [Store::Objects::Tag]
        # @return [Types::FunctionType]
        def parse_type_tag(tag)
          parsed_type = Parsing::TypeParser.new.safe_parse(tag.text).change_root(convert_lexical_scope_literals(tag.lexical_scope))
          parsed_type.is_a?(Types::FunctionType) ? parsed_type : Types::FunctionType.new(return_type: parsed_type)
        end

        # @return [Hash]
        def parameter_options
          @parameter_options ||= {
            required_parameters: parameters.required_parameters.map(&method(:type_of)),
            optional_parameters: parameters.optional_parameters.map(&:first).map(&method(:type_of)),
            rest_parameter: parameters.rest_parameter ? type_of(parameters.rest_parameter) : nil,
            post_parameters: parameters.post_parameters.map(&method(:type_of)),
            required_keyword_parameters: parameters.required_keyword_parameters.map(&method(:type_of)),
            optional_keyword_parameters: parameters.optional_keyword_parameters.map(&:first).map(&method(:type_of)),
            keyword_rest_parameter: parameters.keyword_rest_parameter ? type_of(parameters.keyword_rest_parameter) : nil,
            block_parameter: parameters.block_parameter ? type_of(parameters.block_parameter) : nil,
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

        # @return [Array<Types::Base>]
        def return_types
          @return_types ||= parse_yard_type_tags(return_tags)
        end

        # @param tags [Array<Store::Objects::Tag>]
        # @return [Array<Types::Base>]
        def parse_yard_type_tags(tags)
          tags.map do |tag|
            tag.yard_types.empty? ? Types::UnknownType.new('nodoc') : Types.parse_type_strings(tag.yard_types).change_root(convert_lexical_scope_literals(tag.lexical_scope))
          end
        end

        # @return [{ String => Types::Base }]
        def param_type_table
          @param_type_table ||= param_tags.map(&:name).zip(parse_yard_type_tags(param_tags)).group_by(&:first).map { |k, v| [k, Types::UnionType.new(v.map(&:last))] }.to_h
        end

        # @param lexical_scope_literals [Array<String>]
        # @param [Array<Path>]
        def convert_lexical_scope_literals(lexical_scope_literals)
          lexical_scope_literals.map { |literal| Path.new(literal) } + [Path.new('Object')]
        end
      end
    end
  end
end
