require 'parslet'

module Yoda
  module Parsing
    class TypeParser
      # @return [Store::Types::Base]
      def parse(str)
        Generator.new.apply(Parser.new.parse(str))
      end

      # @return [Store::Types::Base, nil]
      def safe_parse(str)
        parse(str)
      rescue Parslet::ParseFailed => failure
        nil
      end

      class Parser < Parslet::Parser
        rule(:space) { match('\s').repeat(1) }
        rule(:space?) { space.maybe }

        rule(:special_value) { str('void') | str('nil') | str('true') | str('false') }
        rule(:any_type) { str('any').as(:any_type) }
        rule(:keyword) { match['a-z'] >> match['a-zA-Z0-9_'].repeat(1) }
        rule(:generic_name) { constant_name }
        rule(:constant_name) { match['A-Z'] >> match['a-zA-Z0-9_'].repeat }
        rule(:constant_full_name) { str('::').maybe >> (constant_name >> str('::')).repeat >> constant_name }

        rule(:required_param) { type.as(:required) }
        rule(:optional_param) { str('?') >> space? >> type.as(:optional) }
        rule(:rest_param) { str('*') >> space? >> type.as(:rest) }
        rule(:required_keyword_param) { keyword.as(:required_keyword) >> str(':') >> space? >> type.as(:type_for_keyword) }
        rule(:optional_keyword_param) { keyword.as(:optinal_keyword) >> str('?:') >> space? >> type.as(:type_for_keyword) }
        rule(:keyword_rest_param) { str('**') >> space? >> type.as(:keyword_rest) }
        rule(:block_param) { str('&') >> space? >> type.as(:block) }

        rule(:context) { str('(') >> space? >> type >> space? >> str(')') }
        rule(:param) { keyword_rest_param | block_param | optional_param | rest_param | required_keyword_param | optional_keyword_param | required_param }
        rule(:params_inner) { param >> (space? >> str(',') >> space? >> param).repeat }
        rule(:params) { str('(') >> space? >> params_inner >> space? >> str(')') }
        rule(:generic_abs) { str('<') >> space? >> generic_name >> (space? >> str(',') >> space? >> generic_name).repeat >> space? >> str('>') }
        rule(:function_type_inner) { params.as(:params) >> space? >> str('->') >> space? >> type.as(:return_type) }
        rule(:function_type_inner_with_context) { context.maybe.as(:context) >> space? >> function_type_inner }
        rule(:function_type) { generic_abs.maybe.as(:generic_abs) >> space? >> (function_type_inner | function_type_inner_with_context).as(:generic_abs_body) }

        rule(:self_instance_type) { str('self') >> space? >> str('.') >> space? >> str('instance') }
        rule(:self_class_type) { str('self') >> space? >> str('.') >> space? >> str('class') }
        rule(:self_type) { str('self') }

        rule(:instance_type) { constant_full_name.as(:instance_type) }
        rule(:module_type) { constant_full_name.as(:module_type) >> space? >> str('.') >> space? >> (str('class') | str('module')) }
        rule(:value_type) { special_value.as(:value_type) }
        rule(:sequence_type) { (str('[') >> space? >> type >> (space? >> str(',') >> space? >> type).repeat >> space? >> str(']')).as(:sequence_type) }

        rule(:type_with_paren) { str('(') >> type >> str(')') }
        rule(:simple_type) { function_type | type_with_paren | sequence_type | value_type | any_type | module_type | instance_type }

        rule(:generic_type_params) { str('<') >> space? >> type >> (space? >> str(',') >> space? >> type).repeat >> space? >> str('>') }
        rule(:generic_type) { simple_type.as(:base_type) >> (space? >> generic_type_params.as(:generic_type_params)).maybe }
        rule(:type_without_union) { generic_type }
        rule(:union_type) { (type_without_union >> (space? >> str('|') >> space? >> type).repeat(1)).as(:union_type) }

        rule(:type) { union_type | generic_type }

        rule(:base) { type }
        root :base
      end

      class Generator < Parslet::Transform
        rule(required: simple(:type)) { Param.new(:required, type) }
        rule(optional: simple(:type)) { Param.new(:optional, type) }
        rule(rest: simple(:type)) { Param.new(:rest, type) }
        rule(required_keyword: simple(:keyword), type_for_keyword: simple(:type)) { Param.new(:keyword_required, type, keyword.to_s) }
        rule(optional_keyword: simple(:keyword), type_for_keyword: simple(:type)) { Param.new(:keyword_optional, type, keyword.to_s) }
        rule(keyword_rest: simple(:type)) { Param.new(:keyword_rest, type) }
        rule(block: simple(:type)) { Param.new(:block, type) }

        rule(context: simple(:context), params: sequence(:param_types), return_type: simple(:return_type)) { create_function_type(context, param_types, return_type) }
        rule(context: simple(:context), params: simple(:param_type), return_type: simple(:return_type)) { create_function_type(context, [param_type], return_type) }
        rule(params: sequence(:param_types), return_type: simple(:return_type)) { Generator.create_function_type(nil, param_types, return_type) }
        rule(params: simple(:param_type), return_type: simple(:return_type)) { Generator.create_function_type(nil, [param_type], return_type) }

        rule(instance_type: simple(:class_name)) { Store::Types::InstanceType.new(class_name.to_s) }
        rule(module_type: simple(:module_name)) { Store::Types::ModuleType.new(module_name.to_s) }
        rule(value_type: simple(:value_name)) { Store::Types::ValueType.new(value_name.to_s) }
        rule(any_type: simple(:any)) { Store::Types::AnyType.new }

        rule(sequence_type: simple(:type)) { Store::Types::SequenceType.new(Store::Types::InstanceType.new('::Array'), [type]) }
        rule(sequence_type: sequence(:types)) { Store::Types::SequenceType.new(Store::Types::InstanceType.new('::Array'), types) }

        rule(generic_abs: simple(:generic_abs), generic_abs_body: simple(:type)) { type }

        rule(base_type: simple(:base_type)) { base_type }
        rule(base_type: simple(:base_type), generic_type_params: simple(:type_param)) { Store::Types::GenericType.new(base_type, [type_param]) }
        rule(base_type: simple(:base_type), generic_type_params: sequence(:type_params)) { Store::Types::GenericType.new(base_type, type_params) }
        rule(union_type: sequence(:types)) { Store::Types::UnionType.new(types) }

        def self.create_function_type(context, param_types, return_type)
          func_options = param_types.each_with_object({ context: context, return_type: return_type }).with_index do |(param, func_options), index|
            case param.kind
            when :required
              if func_options[:rest_parameter]
                func_options[:post_parameters] ||= []
                func_options[:post_parameters].push(["arg#{index}", param.type])
              else
                func_options[:parameters] ||= []
                func_options[:parameters].push(["arg#{index}", param.type, nil])
              end
            when :optional
              func_options[:parameters] ||= []
              func_options[:parameters].push(["arg#{index}", param.type, 'default'])
            when :rest
              func_options[:rest_parameter] = ["arg#{index}", param.type]
            when :required_keyword
              func_options[:keyword_parameters] ||= []
              func_options[:keyword_parameters].push([param.keyword, param.type, 'default'])
            when :optional_keyword
              func_options[:keyword_parameters] ||= []
              func_options[:keyword_parameters].push([param.keyword, param.type, nil])
            when :keyword_rest
              func_options[:keyword_rest_parameter] = ["arg#{index}", param.type]
            when :block
              func_options[:block_parameter] = ["arg#{index}", param.type]
            end
          end

          Store::Types::FunctionType.new(func_options)
        end

        class Param
          attr_reader :kind, :type, :keyword
          def initialize(kind, type, keyword = nil)
            @kind = kind
            @keyword = keyword
            @type = type
          end
        end
      end
    end
  end
end
