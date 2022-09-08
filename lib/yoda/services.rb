module Yoda
  module Services
    require 'yoda/services/evaluator'
    require 'yoda/services/current_node_explain'
    require 'yoda/services/comment_completion'
    require 'yoda/services/code_completion'
    require 'yoda/services/loadable_path_resolver'
    require 'yoda/services/signature_discovery'

    class Catalog
      # @return [Model::Environment]
      attr_reader :environment

      # @param environment [Model::Environment]
      def initialize(environment:)
        @environment = environment
      end

      # @param ast [::Parser::AST::Node]
      # @return [Evaluator]
      def evaluator(ast:)
        Evaluator.new(ast: ast, environment: environment)
      end

      # @param source   [String]
      # @param location [Parsing::Location]
      # @return [CurrentNodeExplain]
      def current_node_explain(source:, location:)
        CurrentNodeExplain.from_source(environment: environment, source: source, location: location)
      end

      # @param source   [String]
      # @param location [Parsing::Location]
      # @return [CodeCompletion]
      def code_completion(source:, location:)
        CodeCompletion.new(environment, source, location)
      end

      # @param source   [String]
      # @param location [Parsing::Location]
      # @return [CommentCompletion]
      def comment_completion(source:, location:)
        CommentCompletion.from_source(environment, source, location)
      end

      # @param environment [Model::Environment]
      # @param source   [String]
      # @param location [Parsing::Location]
      # @return [SignatureDiscovery]
      def signature_discovery(source:, location:)
        SignatureDiscovery.from_source(environment: environment, source: source, location: location)
      end
    end
  end
end
