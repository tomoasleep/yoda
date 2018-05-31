module Yoda
  module Model
    class CompletionItem
      # @return [Descriptions::Base]
      attr_reader :description

      # @return [Parsing::Range]
      attr_reader :range

      # @param description [Descriptions::Base]
      # @param range [Parsing::Range]
      def initialize(description:, range:)
        fail ArgumentError, desctiption unless description.is_a?(Descriptions::Base)
        fail ArgumentError, range unless range.is_a?(Parsing::Range)
        @description = description
        @range = range
      end


    end
  end
end
