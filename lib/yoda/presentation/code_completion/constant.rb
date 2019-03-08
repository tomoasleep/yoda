module Yoda
  module Constant
    class Candidates
      def initialize(constant_candidates:, range:, prefix:)
        @constant_candidates = constant_candidates
        @range = range
        @prefix = prefix
      end

      # @param object [Store::Objects::Base]
      # @return [Symbol]
      def complete_item_kind(object)
        case object.kind
        when :class
          :class
        when :module
          :module
        else
          :constant
        end
      end
    end

    class Candidate
    end
  end
end
