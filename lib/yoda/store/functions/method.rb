module Yoda
  module Store
    module Functions
      class Method < Base
        include ParamTagContainer
        include ReturnTagContainer
        include TypeTagContainer

        # @type YARD::CodeObjects::MethodObject
        attr_reader :method_object

        # @param method_object [YARD::CodeObjects::MethodObject]
        def initialize(method_object)
          fail ArgumentError, method_object unless method_object.is_a?(YARD::CodeObjects::MethodObject)
          @method_object = method_object
        end

        # @return [String]
        def name
          method_object.name.to_s
        end

        # @return [Symbol]
        def visibility
          method_object.visibility
        end

        # @abstract
        # @return [Symbol]
        def scope
          method_object.scope
        end

        # @return [String]
        def name_signature
          method_object.namespace.name.to_s + method_object.sep + name.to_s
        end

        # @return [String]
        def docstring
          @method_object.docstring
        end

        # @return [Array<Types::FunctionType>]
        def types
          @types ||= begin
            if !type_tag_types.empty?
              type_tag_types
            elsif !overloads.empty?
              overloads.map(&:types).flatten
            else
              [Types::FunctionType.new(return_type: return_type, **parameter_options)]
            end
          end
        end

        # @return [Overload]
        def overloads
          @overloads ||= method_object.tags(:overload).map { |overload_tag| Overload.new(overload_tag) }
        end

        def namespace
          method_object.namespace
        end

        private

        def type_tags
          method_object.tags(:type)
        end

        def param_tags
          method_object.tags(:param)
        end

        # @return [Array<(String, String)>]
        def parameters
          method_object.parameters
        end

        def return_tags
          method_object.tags(:return)
        end
      end
    end
  end
end
