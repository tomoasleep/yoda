require 'fileutils'

module Yoda
  module Store
    class Project
      require 'yoda/store/project/cache'
      require 'yoda/store/project/dependency'

      # @return [String]
      attr_reader :root_path

      # @return [Registry, nil]
      attr_reader :registry

      # @param root_path [String]
      def initialize(root_path, registry: nil)
        fail ArgumentError, root_path unless root_path.is_a?(String)

        @root_path = File.absolute_path(root_path)
        @registry = registry
      end

      def setup
        return if registry
        make_dir
        @registry = cache.prepare_registry
      end

      # Delete all data from registry
      def clear
        setup
        registry.clear
      end

      # @return [Array<BaseError>]
      def build_cache
        setup
        importer = Actions::ImportProjectDependencies.new(self)
        importer.run
        load_project_files
        importer.errors
      end

      def rebuild_cache
        clear
        build_cache
      end

      def yoda_dir
        File.expand_path('.yoda', root_path)
      end

      # @param source_path [String]
      def read_source(source_path)
        Actions::ReadFile.run(registry, source_path)
      end

      # @return [Array<Dependency>]
      def dependencies
        @dependencies ||= Dependency.build_for_project(self)
      end

      private

      def load_project_files
        Logger.debug('Loading current project files...')
        Instrument.instance.initialization_progress(phase: :load_project_files, message: 'Loading current project files')
        Actions::ReadProjectFiles.new(registry, root_path).run
      end

      def make_dir
        File.exist?(yoda_dir) || FileUtils.mkdir(yoda_dir)
      end

      # @return [Cache]
      def cache
        @cache ||= Cache.build_for(self)
      end
    end
  end
end
