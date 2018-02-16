module Yoda
  module Store
    module FunctionSignatures
      class Overload < Base
        # @return [Store::Objects::MethodObject]
        attr_reader :method_object

        # @return [Store::Objects::Overload]
        attr_reader :overload

        # @param method_object [Store::Objects::MethodObject]
        # @param overload [Store::Objects::Overload]
        def initialize(method_object, overload)
          fail ArgumentError, method_object unless method_object.is_a?(Store::Objects::MethodObject)
          fail ArgumentError, overload unless overload.is_a?(Store::Objects::Overload)
          @method_objecrt = method_object
          @overload = overload
        end

        # @return [Symbol]
        def visibility
          method_object.visibility
        end

        # @return [String]
        def name
          method_object.name
        end

        # @return [String]
        def sep
          method_object.sep
        end

        # @return [String]
        def document
          overload.document || method_object.document
        end

        # @return [Types::FunctionType]
        def type
          @type = type_builder.type
        end

        # @return [Array<(String, Integer, Integer)>]
        def sources
          method_object.sources
        end

        # @return [(String, Integer, Integer), nil]
        def primary_source
          overload.primary_source || method_object.primary_source
        end

        # @return [ParameterList]
        def parameters
          @parameters ||= ParameterList.new(overload.parameters)
        end

        private

        # @return [TypeBuilder]
        def type_builder
          @type_builder ||= TypeBuilder.new(overload.parameters, overload.tag_list)
        end
      end
    end
  end
end
