module Yoda
  module Model
    module FunctionSignatures
      class Method < Base
        # @type Store::Objects::MethodObject
        attr_reader :method_object

        # @param method_object [Store::Objects::MethodObject]
        def initialize(method_object)
          fail ArgumentError, method_object unless method_object.is_a?(Store::Objects::MethodObject)
          @method_object = method_object
        end

        # @return [String]
        def name
          method_object.name.to_s
        end

        # @return [String]
        def sep
          method_object.sep
        end

        # @return [String]
        def namespace_path
          method_object.namespace_path
        end

        # @return [String]
        def docstring
          @method_object.docstring
        end

        # @return [Types::FunctionType]
        def type
          type_builder.type
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
          @parameters ||= ParameterList.new(method_object.parameters)
        end

        private

        # @return [TypeBuilder]
        def type_builder
          @type_builder ||= TypeBuilder.new(method_object.parameters, method_object.tag_list)
        end
      end
    end
  end
end
