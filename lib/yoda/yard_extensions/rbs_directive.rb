module Yoda
  module YARDExtensions
    class RbsDirective < YARD::Tags::Directive
      def call; end

      def after_parse
        return unless handler&.namespace
        create_object
      end

      def create_object
        handler.namespace.add_tag(YARD::Tags::Tag.new(:rbs_signature, tag_body))
      end

      def tag_body
        tag.text
      end
    end
  end
end
