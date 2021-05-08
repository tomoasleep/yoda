module Yoda
  module Model
    class LexicalContext
      include Enumerable

      # @return [Array<Path>]
      attr_reader :paths

      def self.build(paths)
        new(paths: paths.map { |pa| Path.build(pa) })
      end

      # @param paths [Array<Path>]
      def initialize(paths:)
        @paths = paths
      end

      # @return [Array<RBS::Namespace>]
      def to_rbs_context
        paths.map { |path| Namespace(path.to_s) }
      end

      def each(&block)
        paths.each(&block)
      end

      def ==(another)
        eql?(another)
      end

      def eql?(another)
        another.is_a?(LexicalContext) && paths == another.paths
      end

      def hash
        paths.hash
      end
    end
  end
end
