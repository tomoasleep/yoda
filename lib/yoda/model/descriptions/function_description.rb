module Yoda
  module Model
    module Descriptions
      class FunctionDescription < Base
        # @return [FunctionSignatures::Base]
        attr_reader :function

        # @param function [FunctionSignatures::Base]
        def initialize(function)
          fail ArgumentError, function unless function.is_a?(FunctionSignatures::Wrapper)
          @function = function
        end

        def title
          "#{function.namespace_path}#{function.sep}#{function.to_s}"
        end

        def label
          signature
        end

        def signature
          "#{function.to_s}"
        end

        def sort_text
          function.name.to_s
        end

        def parameter_names
          function.parameters.parameter_names
        end

        def to_markdown
          <<~EOS
          **#{title}**

          #{function.document}
          #{tag_documents}
          EOS
        end

        private

        def tag_documents
          function.tags.map { |tag| tag_document(tag) }.join("  \n") # Commonmark requires 2 spaces for line breaking
        end

        # @param tag [Store::Objects::Tag]
        def tag_document(tag)
          str = "@#{tag.tag_name}"
          str += " `#{tag.name}`" if tag.name
          str += " [#{tag.yard_types.map { |name| "`#{name}`" }.join(', ')}]" if tag.yard_types && !(tag.yard_types.empty?)
          str += " :#{tag.option_key}" if tag.option_key
          str += " (#{tag.option_default})" if tag.option_default
          str += " #{tag.text.chomp}" if tag.text
        end
      end
    end
  end
end
