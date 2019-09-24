require 'fileutils'

module Yoda
  module Store
    class Project
      require 'yoda/store/project/cache'
      require 'yoda/store/project/dependency'

      # @note This number must be updated when breaking change is added.
      REGISTRY_VERSION = 4

      # @return [String]
      attr_reader :root_path

      # @param root_path [String]
      def initialize(root_path)
        fail ArgumentError, root_path unless root_path.is_a?(String)

        @root_path = File.absolute_path(root_path)
      end
      
      # @return [Registry]
      def registry
        @registry ||= Registry::ProjectRegistry.for_project(self)
      end

      # @return [Dependency]
      def dependency
        @dependency ||= Dependency.new(self)
      end

      # @return [Cache]
      def cache
        @cache ||= Cache.build_for(self)
      end

      def yoda_dir
        File.expand_path('.yoda', root_path)
      end

      def setup
        import_project_dependencies
        load_project_files
      end
      alias build_cache setup

      # @return [Array<BaseError>]
      def import_project_dependencies
        Actions::ImportProjectDependencies.new(self).run.errors
      end

      # @param source_path [String]
      def read_source(source_path)
        Actions::ReadFile.run(registry, source_path)
      end

      def registry_name
        @registry_name ||= begin
          digest = Digest::SHA256.new
          digest.update(RUBY_VERSION)
          digest.update(Project::REGISTRY_VERSION.to_s)
          digest.update(Adapters.default_adapter_class.type.to_s)
          digest.hexdigest
        end
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
    end
  end
end
