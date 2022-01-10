module Yoda
  module Services
    # CurrentNodeExplain shows help for the current node.
    class CurrentNodeExplain
      require 'yoda/services/current_node_explain/comment_signature'

      # @return [Evaluator]
      attr_reader :evaluator

      # @return [Parsing::Location]
      attr_reader :location

      # @param environment [Model::Environment]
      # @param source   [String]
      # @param location [Parsing::Location]
      # @return [CurrentNodeExplain]
      def self.from_source(environment:, source:, location:)
        ast, _ = Parsing.parse_with_comments(source)
        new(
          evaluator: Evaluator.new(environment: environment, ast: ast),
          location: location
        )
      end

      # @param evaluator [Evaluator]
      # @param location [Parsing::Location]
      def initialize(evaluator:, location:)
        @evaluator = evaluator
        @location = location
      end

      # @return [Model::NodeSignature, nil]
      def current_node_signature
        return nil if !valid? || !current_node
        @current_node_signature ||= Model::NodeSignatures.for_node_info(current_node_info)
      end

      # @return [CommentSignature, nil]
      def current_comment_signature
        return nil if !valid? || !current_comment || !commenting_node_info
        @current_comment_signature ||= CommentSignature.new(comment: current_comment, node_info: commenting_node_info, location: location)
      end

      # @return [true, false]
      def valid?
        !!(current_comment || current_node)
      end

      private

      # @return [Typing::NodeInfo]
      def current_node_info
        @current_node_info ||= evaluator.node_info(current_node)
      end

      # @return [Typing::NodeInfo]
      def commenting_node_info
        @commenting_node_info ||= current_comment&.node ? evaluator.node_info(current_comment&.node) : nil
      end

      # @return [Parser::AST::Node]
      def current_node
        @current_node ||= evaluator.ast.positionally_nearest_child(location)
      end

      # @return [AST::CommentBlock, nil]
      def current_comment
        @current_comment || evaluator.ast.positionally_nearest_comment(location)
      end
    end
  end
end
