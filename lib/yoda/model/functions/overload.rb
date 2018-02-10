module Yoda
  module Store
    module Functions
      class Overload < Base
        include ParamTagContainer
        include ReturnTagContainer
        include TypeTagContainer

        # @return [Store::Objects::MethodObject]
        attr_reader :method_object

        # @return [Store::Objects::Tag]
        attr_reader :overload_tag

        # @param method_object [Store::Objects::MethodObject]
        # @param overload_tag [Store::Objects::Tag]
        def initialize(method_object, overload_tag)
          fail ArgumentError, overload_tag unless overload_tag.is_a?(Store::Objects::Tag) && overload_tag.tag_name == 'overload'
          @overload_tag = overload_tag
        end

        # @return [Symbol]
        def visibility
          parent_method.visibility
        end

        # @return [String]
        def name
          parent_method.name
        end

        # @abstract
        # @return [Symbol]
        def scope
          parent_method.scope
        end

        # @return [String]
        def name_signature
          parent_method.name_signature
        end

        # @return [String]
        def docstring
          overload_tag.docstring
        end

        # @return [Array<Overload>]
        def overloads
          @overloads ||= overload_tag.tags(:overload).map { |overload_tag| Overload.new(overload_tag) }
        end

        # @return [Array<Types::FunctionType>]
        def types
          @types ||= begin
            if !type_tag_types.empty?
              type_tag_types
            else
              [Types::FunctionType.new(return_type: return_type, **parameter_options)]
            end
          end
        end

        def namespace
          parent_method.namespace
        end

        # @return [Array<[String, Integer]>]
        def defined_files
          parent_method.files
        end

        private

        def type_tags
          overload_tag.tags(:type)
        end

        def param_tags
          overload_tag.tags(:param)
        end

        def parameters
          overload_tag.parameters
        end

        def return_tags
          overload_tag.tags(:return)
        end

        # @return [Method]
        def parent_method
          @parent_method ||= Method.new(method_object)
        end
      end
    end
  end
end
