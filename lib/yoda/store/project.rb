require 'fileutils'

module Yoda
  module Store
    class Project
      require 'yoda/store/project/cache'
      require 'yoda/store/project/builder'

      # @type String
      attr_reader :root_path

      # @type Registry
      attr_reader :registry

      # @param root_path [String]
      def initialize(root_path)
        fail ArgumentError, root_path unless root_path.is_a?(String)

        @root_path = File.absolute_path(root_path)
        @registry = Registry.new
      end

      def clean
      end

      def setup
        YARD::Logger.instance(STDERR)
        make_dir
        cache.setup
        load_project_files
        self
      end

      def rebuild_cache(progress: false)
        make_dir
        cache.build(progress: progress)
      end

      # @param source_path [String]
      def read_source(source_path)
        Actions::ReadFile.run(registry, source_path)
      end

      def yoda_dir
        File.expand_path('.yoda', root_path)
      end

      private

      def make_dir
        File.exist?(yoda_dir) || FileUtils.mkdir(yoda_dir)
      end

      def load_project_files
        Actions::ReadProjectFiles.new(registry, root_path).run
      end

      def cache
        @cache ||= Cache.new(self)
      end
    end
  end
end
