module Yoda
  module Store
    module Functions
      class Constructor < Base
        # @type YARD::CodeObjects::MethodObject
        attr_reader :constructor_object

        # @param overload_tag [YARD::CodeObjects::MethodObject]
        def initialize(constructor_object)
          @constructor_object = constructor_object
        end

        # @return 
        def types
          base_method.types
        end

        def name
          'new'
        end

        def visibility
          :public
        end

        def scope
          :class
        end

        # @return [String]
        def docstring
          base_method.docstring
        end

        def name_signature
          "#{constructor_object.namespace.name}.new"
        end

        # @return [Array<Overload>]
        def overloads
          @overloads ||= base_method.tags(:overload).map { |overload_tag| Overload.new(overload_tag) }
        end

        def namespace
          base_method.namespace
        end

        private

        # @return [Method]
        def base_method
          @base_method ||= Method.new(constructor_object)
        end
      end
    end
  end
end
