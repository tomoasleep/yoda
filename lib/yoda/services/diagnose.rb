module Yoda
  module Services
    class Diagnose
      # @return [Evaluator]
      attr_reader :evaluator

      # @param environment [Model::Environment]
      # @param source   [String]
      # @return [CurrentNodeExplain]
      def self.from_source(environment:, source:)
        ast, _ = Parsing.parse_with_comments(source)
        new(
          evaluator: Evaluator.new(environment: environment, ast: ast),
        )
      end

      # @param evaluator [Evaluator]
      def initialize(evaluator:)
        @evaluator = evaluator
      end

      # @return [Array<Typing::Diagnostics::Base>]
      def diagnostics
        evaluator.tracer.all_diagnostics
      end
    end
  end
end
