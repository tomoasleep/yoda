module Yoda
  module Model
    class CompletionItem
      # @return [Descriptions::Base]
      attr_reader :description

      # @return [Parsing::Range]
      attr_reader :range

      # @return [String]
      attr_reader :prefix

      # @param description [Descriptions::Base]
      # @param range       [Parsing::Range]
      # @param prefix      [String, nil]
      def initialize(description:, range:, prefix: nil)
        fail ArgumentError, desctiption unless description.is_a?(Descriptions::Base)
        fail ArgumentError, range unless range.is_a?(Parsing::Range)
        @description = description
        @range = range
        @prefix = prefix || ''
      end

      # @return [String]
      def edit_text
        prefix + description.sort_text
      end

    end
  end
end
