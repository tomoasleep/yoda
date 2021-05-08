module Yoda
  module Typing
    module Types
      # Generator provides construction methods for various type classes.
      class Generator
        # @return [Model::Environment]
        attr_reader :environment

        # @param registry [Contexts::BaseContext]
        def initialize(environment:)
          @environment = environment
        end

        # @param [RBS::Types::t]
        # @return [Type]
        def wrap_rbs_type(rbs_type)
          Type.new(environment: environment, rbs_type: rbs_type)
        end

        # @return [Type<RBS::Types::Bases::Bool>]
        def boolean_type
          wrap_rbs_type(RBS::Types::Bases::Bool.new(location: nil))
        end

        # @return [Type<RBS::Types::Literal>]
        def true_type
          literal_type(true)
        end

        # @return [Type<RBS::Types::Literal>]
        def false_type
          literal_type(false)
        end

        # @return [Type<RBS::Types::Bases::Nil>]
        def nil_type
          wrap_rbs_type(RBS::Types::Bases::Nil.new(location: nil))
        end

        # @param literal [Integer, Symbol, String, TrueClass, FalseClass]
        # @return [Type<RBS::Types::Literal, RBS::Types::ClassInstance>]
        def string_type(literal = nil)
          if literal
            literal_type(literal.to_s)
          else
            instance_type_at('::String')
          end
        end

        # @param literal [Integer, Symbol, String, TrueClass, FalseClass]
        # @return [Type<RBS::Types::Literal, RBS::Types::ClassInstance>]
        def symbol_type(literal = nil)
          if literal
            literal_type(literal.to_sym)
          else
            instance_type_at('::Symbol')
          end
        end

        # @param literal [Integer, Symbol, String, TrueClass, FalseClass]
        # @return [Type<RBS::Types::Literal>]
        def literal_type(literal)
          wrap_rbs_type(RBS::Types::Literal.new(literal: literal, location: nil))
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def array_type
          instance_type_at('::Array')
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def hash_type
          instance_type_at('::Hash')
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def range_type
          instance_type_at('::Range')
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def regexp_type
          instance_type_at('::RegExp')
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def proc_type
          instance_type_at('::Proc')
        end

        # @return [Type<RBS::Types::Literal, RBS::Types::ClassInstance>]
        def integer_type(literal = nil)
          if literal
            literal_type(literal.to_i)
          else
            instance_type_at('::Integer')
          end
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def float_type
          instance_type_at('::Float')
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def numeric_type
          instance_type_at('::Numeric')
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def object_type
          instance_type_at('::Object')
        end

        # @param object_class [Store::Objects::NamespaceObject]
        # @return [Type<RBS::Types::ClassInstance>]
        def singleton_type(object_class)
          singleton_type_at(object_class.path)
        end

        # @param object_class [Store::Objects::NamespaceObject]
        # @return [Type<RBS::Types::ClassInstance>]
        def instance_type(object_class)
          instance_type_at(object_class.path)
        end

        # @param record [Hash{Symbol => RBS::Types::t}]
        # @return [Type<RBS::Types::Record>]
        def record_type(record)
          wrap_rbs_type(RBS::Types::Record.new(fields: record, location: nil))
        end

        # @return [Type<RBS::Types::Bases::Any>]
        def any_type
          wrap_rbs_type(RBS::Types::Bases::Any.new(location: nil))
        end

        # @param reason [String, nil]
        # @return [Type<RBS::Types::Bases::Any>]
        def unknown_type(reason: nil)
          Logger.trace("Use unknown type because #{reason}") if reason
          any_type
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def class_class
          singleton_type_at('::Class')
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def module_class
          singleton_type_at('::Module')
        end

        # @return [Type<RBS::Types::ClassInstance>]
        def object_class
          singleton_type_at('::Object')
        end

        # @param args [Array<Type, RBS::Types::t>]
        # @return [Type<RBS::Types::ClassInstance>]
        def instance_type_at(path, args: [])
          name = to_type_name(path)
          name ? wrap_rbs_type(RBS::Types::ClassInstance.new(name: name, args: args.map(&method(:unwrap)), location: nil)) : unknown_type(reason: "#{path} does not exists")
        end

        # @return [Type<RBS::Types::ClassSingleton>]
        def singleton_type_at(path)
          name = to_type_name(path)
          name ? wrap_rbs_type(RBS::Types::ClassSingleton.new(name: name, location: nil)) : unknown_type(reason: "#{path} does not exists")
        end

        # @param types [Array<Base>]
        # @return [Type<RBS::Types::Union>]
        def union_type(*types)
          wrap_rbs_type(RBS::Types::Union.new(types: types.map(&method(:unwrap)), location: nil))
        end

        # @param required_parameters [Array<Base>]
        # @param optional_parameters [Array<Base>]
        # @param rest_parameter [Base, nil]
        # @param post_parameters [Array<Base>]
        # @param required_keyword_parameters [Array<(String, Base)>]
        # @param optional_keyword_parameters [Array<(String, Base)>]
        # @param keyword_rest_parameter [Base, nil]
        # @param return_type [Base]
        # @return [Type<RBS::Types::Function>]
        def function_type(
          return_type:,
          required_parameters: [],
          optional_parameters: [],
          rest_parameter: nil,
          post_parameters: [],
          required_keyword_parameters: [],
          optional_keyword_parameters: [],
          keyword_rest_parameter: nil
        )
          build_param = lambda { |type| RBS::Types::Function::Param.new(type: unwrap(type), name: nil) }
          build_keyword = lambda { |(name, type)| [name.to_sym, RBS::Types::Function::Param.new(type: unwrap(type), name: name.to_sym)] }
          function_type = RBS::Types::Function.new(
            required_positionals: required_parameters.map(&build_param),
            optional_positionals: optional_parameters.map(&build_param),
            rest_positionals: rest_parameter&.yield_self(&build_param),
            trailing_positionals: post_parameters.map(&build_param),
            required_keywords: required_keyword_parameters.map(&build_keyword).to_h,
            optional_keywords: optional_keyword_parameters.map(&build_keyword).to_h,
            rest_keywords: keyword_rest_parameter&.yield_self(&build_param),
            return_type: unwrap(return_type),
          )
          wrap_rbs_type(function_type)
        end

        # @param required_parameters [Array<Base>]
        # @param optional_parameters [Array<Base>]
        # @param rest_parameter [Base, nil]
        # @param post_parameters [Array<Base>]
        # @param required_keyword_parameters [Array<(String, Base)>]
        # @param optional_keyword_parameters [Array<(String, Base)>]
        # @param keyword_rest_parameter [Base, nil]
        # @param return_type [Base]
        # @return [RBS::MethodType]
        def rbs_method_type(**kwargs)
          RBS::MethodType.new(
            type_params: [],
            type: unwrap(function_type(**kwargs)),
            block: nil,
            location: nil,
          )
        end

        # @param method_type [RBS::MethodType]
        # @return [RBS::MethodType]
        def fresh_params_of_method_type(method_type)
          new_type_params = method_type.type_params.map(&method(:append_id_to_type_var))
          new_type_variables = RBS::Types::Variable.build(new_type_params)

          subst = RBS::Substitution.build(method_type.type_params, new_type_variables)

          method_type.update(
            type_params: new_type_params,
            type: method_type.type.sub(subst),
            block: method_type.block&.sub(subst),
          )
        end

        private

        def unwrap(type)
          if type.respond_to?(:rbs_type)
            type.rbs_type
          else
            type
          end
        end
          

        # @param var [Symbol]
        # @return [Symbol]
        def append_id_to_type_var(var)
          "#{var}##{object_id}-#{new_id}".to_sym
        end

        # @param path [String, Path, ScopedPath]
        # @return [RBS::TypeName, nil]
        def to_type_name(path)
          environment.resolve_rbs_type_name(path)
        end

        # @return [Converter]
        def build_converter(**kwargs)
          Converter.new(self, **kwargs)
        end

        def normalize_path(path)
          case path
          when Model::ScopedPath
            path.paths.first.to_s
          when Model::Path
            path.to_s
          when String, Symbol
            path.to_s
          else
            fail TypeError, path
          end
        end

        # @return [Integer]
        def new_id
          @id ||= 0
          @id += 1
        end
      end
    end
  end
end
