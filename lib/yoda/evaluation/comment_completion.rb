module Yoda
  module Evaluation
    class CommentCompletion
      require 'yoda/evaluation/comment_completion/base_provider'
      require 'yoda/evaluation/comment_completion/param_provider'
      require 'yoda/evaluation/comment_completion/tag_provider'
      require 'yoda/evaluation/comment_completion/type_provider'

      # @type Store::Registry
      attr_reader :registry

      # @type ::Parser::AST::Node
      attr_reader :ast

      # @type Array<::Parser::Source::Comment>
      attr_reader :comments

      # @type Location
      attr_reader :location

      # @param registry [Store::Registry]
      # @param ast      [::Parser::AST::Node]
      # @param comments [Array<::Parser::Source::Comment>]
      # @param location [Location]
      def initialize(registry, ast, comments, location)
        @registry = registry
        @ast = ast
        @comments = comments
        @location = location
      end

      # @return [true, false]
      def available?
        comment? && providers.any?(&:available?)
      end

      # @return [Array<Model::CompletionItem>]
      def candidates
        available? ? providers.select(&:available?).map(&:candidates).flatten : []
      end

      private

      # @return [Array<CommentCompletion::BaseProvider>]
      def providers
        [param_provider, tag_provider, type_provider]
      end

      # @return [ParamProvider]
      def param_provider
        @param_provider ||= ParamProvider.new(registry, ast, comments, location)
      end

      # @return [TagProvider]
      def tag_provider
        @tag_provider ||= TagProvider.new(registry, ast, comments, location)
      end

      # @return [TypeProvider]
      def type_provider
        @type_provider ||= TypeProvider.new(registry, ast, comments, location)
      end

      def comment?
        return @is_comment if instance_variable_defined?(:@is_comment)
        @is_comment = !!Parsing::Query::CurrentCommentQuery.new(comments, location).current_comment
      end
    end
  end
end
