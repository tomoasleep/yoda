require 'unparser'

module Yoda
  module Model
    module Descriptions
      class NodeDescription < Base
        # @return [::Parser::AST::Node]
        attr_reader :node

        # @return [TypeExpressions::Base]
        attr_reader :type

        # @param node  [::Parser::AST::Node]
        # @param type [TypeExpressions::Base]
        def initialize(node, type)
          @node = node
          @type = type
        end

        # @return [String]
        def title
          node_body
        end

        # @return [String]
        def sort_text
          node_body
        end

        # @return [String]
        def to_markdown
          <<~EOS
          #{node_body.gsub("\n", ";")}: #{type}
          EOS
        end

        private

        # @return [String]
        def node_body
          @node_body ||= Unparser.unparse(node)
        end
      end
    end
  end
end
