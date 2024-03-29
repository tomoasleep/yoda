module Yoda
  module Model
    module FunctionSignatures
      class Method < Base
        # @return [Store::Objects::MethodObject::Connected]
        attr_reader :method_object

        # @param method_object [Store::Objects::MethodObject::Connected]
        def initialize(method_object)
          fail ArgumentError, method_object unless method_object.is_a?(Store::Objects::MethodObject::Connected)
          @method_object = method_object
        end

        # @return [String]
        def name
          method_object.name.to_s
        end

        # @return [String]
        def sep
          method_object.separator
        end

        # @return [String]
        def namespace_path
          method_object.namespace_path
        end

        # @return [String]
        def document
          @method_object.document
        end

        # @return [Array<Store::Objects::Tag>]
        def tags
          method_object.resolved_tag_list
        end

        # @return [TypeExpressions::FunctionType]
        def type
          type_builder.type
        end

        # @param env [Environment]
        # @return [RBS::MethodType]
        def rbs_type(env)
          RBS::MethodType.new(
            type_params: [],
            type: type.to_rbs_type(env),
            block: nil,
            location: nil,
          )
        end

        # @return [Array<(String, Integer, Integer)>]
        def sources
          method_object.source
        end

        # @return [(String, Integer, Integer), nil]
        def primary_source
          method_object.primary_source
        end

        # @return [ParameterList]
        def parameters
          method_object.parameters
        end

        def parameter_type_of(param)
          type_builder.type_of(param)
        end

        private

        # @return [TypeBuilder]
        def type_builder
          @type_builder ||= TypeBuilder.new(parameters, method_object.resolved_tag_list)
        end
      end
    end
  end
end
