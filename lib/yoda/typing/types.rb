module Yoda
  module Typing
    module Types
      class << self
        def boolean_type
          Union.new([true_type, false_type])
        end

        def true_type
          Instance.new('::TrueClass')
        end

        def false_type
          Instance.new('::FalseClass')
        end

        def nil_type
          Instance.new('::NilClass')
        end

        def unknown_type
          Unknown.new
        end
      end

      # @abstract
      class Base
        def reference?
          false
        end

        # @abstract
        # @param resolver [Resolver]
        # @return [Store::Types::Base]
        def resolve(resolver)
          fail NotImplemetedError
        end
      end

      class Any
        def resolve(resolver)
          Store::Types::AnyType.new
        end
      end

      class Unknown
        def resolve(resolver)
          Store::Types::UnknownType.new
        end
      end

      class Var < Base
        def initialize(name, ref = nil)
          @ref = ref
        end

        # @param new_ref [Base]
        def ref=(new_ref)
          return if new_ref == self
          @ref = new_ref
        end

        def reference?
          true
        end

        # @return [Base, nil]
        def ref
          @ref&.ref
        end

        def resolve(resolver)
          ref&.resolve(resolver) || Store::Types::UnknownType.new
        end
      end

      class Instance < Base
        attr_reader :namespace

        def initialize(namespace)
          @namespace = namespace
        end

        def resolve(resolver)
          Store::Types::InstanceType.new(namespace)
        end
      end

      class Klass < Base
        attr_reader :namespace

        def initialize(namespace)
          @namespace = namespace
        end

        def resolve(resolver)
          Store::Types::ModuleType.new(namespace)
        end
      end

      class Union < Base
        # @return [Array<Base>]
        attr_reader :types
        def initialize(*types)
          @types = types
        end

        def resolve(resolver)
          Store::Types::UnionType.new(types.map { |type| resolve(type) })
        end
      end

      class Function < Base
        # @return [Base, nil]
        attr_reader :context

        # @return [Array<Base>]
        attr_reader :parameters

        # @return [Array<Base>]
        attr_reader :rest_parameter

        # @return [Array<Base>]
        attr_reader :post_parameters

        # @return [Array<(String, Base)>]
        attr_reader :keyword_parameters

        # @return [Base]
        attr_reader :keyword_rest_parameter

        # @return [(String, Base), nil]
        attr_reader :block_parameter

        # @return [Base]
        attr_reader :return_type

        # @param context [Base]
        # @param parameters [Array<Base>]
        # @param rest_parameter [Base, nil]
        # @param post_parameters [Array<Base>]
        # @param keyword_parameters [Array<(String, Base)>]
        # @param keyword_rest_parameter [Base, nil]
        # @param block_parameter [Base, nil]
        # @param return_type [Base]
        def initialize(context: nil, return_type:, parameters: [], rest_parameter: nil, post_parameters: [], keyword_parameters: [], keyword_rest_parameter: nil, block_parameter: nil)
          @context = context
          @parameters = parameters
          @keyword_parameters = keyword_parameters
          @rest_parameter = rest_parameter
          @post_parameters = post_parameters
          @keyword_rest_parameter = keyword_rest_parameter
          @block_parameter = block_parameter
          @return_type = return_type
        end

        def resolve(resolver)
          Store::Types::FunctionType.new(
            context: context.resolve(resolver),
            return_type: return_type.resolve(resolver),
            parameters: parameters.map { |type| type.resolve(resolver) },
            rest_parameter: rest_parameter&.resolve(resolver),
            post_parameters: post_parameters.map { |type| type.resolve(resolver) },
            keyword_parameters: keyword_parameters.map { |keyword, type| [keyword, type.resolve(resolver)] },
            keyword_rest_parameter: keyword_rest_parameter&.resolve(resolver),
            block_parameter: block_parameter&.resolve(resolver),
          )
        end
      end

      class Method < Base
        # @return [Base]
        attr_reader :callee

        # @return [String]
        attr_reader :method_name

        # @param callee [Base]
        # @param method_name [String]
        # @param self_call [true, false]
        def initailize(callee, method_name, self_call: false)
          @callee = callee
          @method_name = method_name
        end

        def resolve(resolver)
          callee_type = resolve(callee)
          values = callee_type.instanciate(resolver.registry)
          Store::Types::UnionType.new(values.map do |value|
            value.methods(visibility: visibility).select { |func| func.name == method_name }
          end.flatten)
        end

        def visilibity
          @self_call ? [:private, :public, :protected] : [:public]
        end
      end

      class Generic
        # @param base [Base]
        # @param type_args [Array<Base>]
        def initialize(base, type_args)
          @base = base
          @type_args = type_args
        end
      end

      class Resolver
        # @return [Store::Registry]
        attr_reader :registry

        # @return [Integer]
        attr_reader :level

        # @param type [Base]
        # @return [Store::Types::Base]
        def resolve(type)
          type.resolve(self)
        end

        # @param store_type [Store::Types::Base]
        # @param env [{ String => Store::Types::Base }]
        # @return [Base]
        def convert(store_type)
          case store_type
          when Store::Types::AnyType
            Any.new
          when Store::Types::UnknownType
            Unknown.new
          when Store::Types::GenericType
            # store_type.
          end
        end

        def unify(type1, type2)
          type1 = type1.resolve || type1 if type1.reference?
          type2 = type2.resolve || type2 if type2.reference?

          if type1.is_a?(Var)
            type1.ref = type2
          elsif type2.is_a?(Var)
            type2.ref = type1
          else
            # TODO
          end
        end
      end
    end
  end
end
