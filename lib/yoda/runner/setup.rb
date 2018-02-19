module Yoda
  module Runner
    class Setup
      # @return [String]
      attr_reader :dir

      # @param dir [String]
      def initialize(dir = nil)
        @dir = dir || Dir.pwd
      end

      # @param dir [String]
      def self.run(dir = nil)
        new(dir).run
      end

      def run
        project.rebuild_cache(progress: true)
      end

      def project
        @project ||= Store::Project.new(dir)
      end
    end
  end
end
