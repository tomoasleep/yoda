module Yoda
  module Services
    class CommentCompletion
      require 'yoda/services/comment_completion/base_provider'
      require 'yoda/services/comment_completion/param_provider'
      require 'yoda/services/comment_completion/tag_provider'
      require 'yoda/services/comment_completion/type_provider'

      # @return [Model::Environment]
      attr_reader :environment

      # @type ::Parser::AST::Node
      attr_reader :ast

      # @type Array<::Parser::Source::Comment>
      attr_reader :comments

      # @type Location
      attr_reader :location

      # @param environment [Model::Environment]
      # @param ast      [::Parser::AST::Node]
      # @param comments [Array<::Parser::Source::Comment>]
      # @param location [Location]
      def initialize(environment, ast, comments, location)
        @environment = environment
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
        @param_provider ||= ParamProvider.new(environment, ast, comments, location)
      end

      # @return [TagProvider]
      def tag_provider
        @tag_provider ||= TagProvider.new(environment, ast, comments, location)
      end

      # @return [TypeProvider]
      def type_provider
        @type_provider ||= TypeProvider.new(environment, ast, comments, location)
      end

      def comment?
        return @is_comment if instance_variable_defined?(:@is_comment)
        @is_comment = !!Parsing::Query::CurrentCommentQuery.new(comments, location).current_comment
      end
    end
  end
end
