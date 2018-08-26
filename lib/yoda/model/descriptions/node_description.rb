require 'unparser'

module Yoda
  module Model
    module Descriptions
      class NodeDescription < Base
        # @return [::Parser::AST::Node]
        attr_reader :node

        # @return [Typing::Traces::Base]
        attr_reader :trace

        # @param node  [::Parser::AST::Node]
        # @param trace [Typing::Traces::Base]
        def initialize(node, trace)
          @node = node
          @trace = trace
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
          #{node_body.gsub("\n", ";")}: #{trace.type}
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
