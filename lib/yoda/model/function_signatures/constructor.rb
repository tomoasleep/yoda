module Yoda
  module Model
    module FunctionSignatures
      # Constructor provides a signature of `YourClass.new` from `initialize` method of the class.
      class Constructor < Base
        # @return [Store::Objects::NamespaceObject::Connected]
        attr_reader :namespace

        # @return [Store::Objects::MethodObject::Connected]
        attr_reader :initialize_method

        # @param namespace [Store::Objects::NamespaceObject::Connected]
        # @param initialize_method [Store::Objects::MethodObject::Connected]
        def initialize(namespace, initialize_method)
          fail ArgumentError, namespace unless namespace.is_a?(Store::Objects::NamespaceObject::Connected)
          fail ArgumentError, initialize_method if initialize_method && !initialize_method.is_a?(Store::Objects::MethodObject::Connected)

          @namespace = namespace
          @initialize_method = initialize_method
        end

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

        # @return [Array<Store::Objects::Tag>]
        def tags
          initialize_method.resolved_tag_list
        end

        # @return [Array<(String, Integer, Integer)>]
        def sources
          initialize_method.sources
        end

        # @return [ParameterList]
        def parameters
          initialize_method.parameters
        end

        # @return [(String, Integer, Integer), nil]
        def primary_source
          initialize_method.primary_source
        end

        # @return [TypeExpressions::Base, nil]
        def parameter_type_of(param)
          type_builder.type_of(param)
        end

        private

        # @return [TypeBuilder]
        def type_builder
          @type_builder ||= TypeBuilder.new(parameters, tags)
        end
      end
    end
  end
end
