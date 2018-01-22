module Yoda
  module YARDExtensions
    class SigDirective < YARD::Tags::Directive
      def call; end

      def after_parse
        return unless handler && handler.namespace
        create_object
      end

      def create_object
        method_name = name
        scope = parser.state.scope || handler.scope
        visibility = parser.state.visibility || handler.visibility

        method_object = YARD::CodeObjects::MethodObject.new(handler.namespace, method_name, scope)
        method_object.add_tag(TypeTag.new(:type, type_text))

        unless method_object.files
          # Already registered object
          method_object.signature = "def #{method_name}"
          method_object.dynamic = true
          handler.register_file_info(method_object)
          handler.register_source(method_object)
          handler.register_visibility(method_object, visibility)
          handler.register_group(method_object)
          handler.register_module_function(method_object)
        end
      end

      def name
        tag.text.split(' ').first
      end

      def type_text
        tag.text.gsub(/\A\w+\s+/, '')
      end
    end
  end
end
