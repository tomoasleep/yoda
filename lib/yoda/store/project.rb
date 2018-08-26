require 'fileutils'

module Yoda
  module Store
    class Project
      require 'yoda/store/project/cache'
      require 'yoda/store/project/library_doc_loader'

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

      def setup
        make_dir
        cache.register_adapter(registry)
      end

      def clear
        setup
        registry.adapter.clear
      end

      # @return [Array<BaseError>]
      def build_cache
        setup
        loader = LibraryDocLoader.build_for(self)
        loader.run
        load_project_files
        loader.errors
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
