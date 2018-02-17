module Yoda
  module Model
    module FunctionSignatures
      # Constructor provides a signature of `YourClass.new` from `initialize` method of the class.
      class Constructor < Base
        # @type Store::Objects::MethodObject
        attr_reader :initialize_method

        # @param initialize_method [Store::Objects::MethodObject]
        def initialize(constructor_object)
          @initialize_method = initialize_method
        end

        def type
          type_builder.type
        end

        def name
          'new'
        end

        def visibility
          :public
        end

        def sep
          '.'
        end

        def namespace_path
          initialize_method.namespace_path
        end

        # @return [String]
        def document
          initialize_method.document
        end

        # @return [Array<(String, Integer, Integer)>]
        def sources
          initialize_method.sources
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
