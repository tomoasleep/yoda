module Yoda
  module Workers
    class ImportYard
      def initialize()
      end

      # @param dep [Objects::Library::Gem]
      def build_yardoc(dep)
        yardoc_path = FileUtils.yardoc_path(dep)
        run_yardoc(work_dir: dep.full_gem_path, index_path: yardoc_path)
        patch = Store::YardImporter.import(yardoc_path)
      end

      private

      # @param work_dir [String]
      # @param index_path [String]
      def run_yardoc(work_dir:, index_path:)
        Dir.chdir(work_dir) do
          YARD::CLI::Yardoc.run("--no-stats", "--no-output", "-b", index_path, "-c")
        end
      end
    end
  end
end

