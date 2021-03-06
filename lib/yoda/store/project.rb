require 'fileutils'
require 'forwardable'
require 'rbs'
require 'pathname'

module Yoda
  module Store
    class Project
      require 'yoda/store/project/files'
      require 'yoda/store/project/dependency'

      extend Forwardable

      delegate [:cache_dir_path, :yoda_dir_path, :gemfile_lock_path] => :files

      # @return [String, nil]
      attr_reader :root_path

      # @return [String]
      attr_reader :name

      # @param name [String]
      # @param root_path [String, nil]
      def initialize(name:, root_path:)
        @name = name
        @root_path = root_path && File.absolute_path(root_path)
      end
      
      # @return [Registry::ProjectRegistry]
      def registry
        @registry ||= Registry.for_project(self)
      end

      # @return [Dependency]
      def dependency
        @dependency ||= Dependency.new(self)
      end

      # @return [RBS::Environment]
      def rbs_environment
        @rbs_environment ||= begin
          repository = RBS::Repository.new
          config.rbs_repository_paths.each do |repo_path|
            pathname = Pathname(repo_path).expand_path(root_path)
            repository.add(pathname)
          end
          
          loader = RBS::EnvironmentLoader.new(repository: repository)
          config.rbs_signature_paths.each do |sig_path|
            pathname = Pathname(sig_path).expand_path(root_path)
            loader.add(path: pathname)
          end

          config.rbs_libraries.each do |library|
            loader.add(library: library)
          end

          RBS::Environment.from_loader(loader).resolve_type_names
        end
      end

      # @return [Model::Environment]
      def environment
        @environment ||= Model::Environment.from_project(self)
      end

      def setup
        files.make_dir
        import_project_dependencies
        rbs_environment
        load_project_files
      end
      alias build_cache setup

      def clear
        files.clear_dir
      end

      # @return [Config]
      def config
        content = files.config_file_path && File.exists?(files.config_file_path) && File.read(files.config_file_path)
        @config ||= Config.from_yaml_data(content || '')
      end

      def reset
        clear
        setup
      end

      # @return [Array<BaseError>]
      def import_project_dependencies
        Actions::ImportProjectDependencies.new(self).run.errors
      end

      # @param source_path [String]
      def read_source(source_path)
        Actions::ReadFile.run(registry, source_path)
      end

      def registry_name
        @registry_name ||= Registry.registry_name
      end

      private

      def on_memory?
        !root_path
      end

      # @return [Files]
      def files
        @files ||= Files.new(self)
      end

      def load_project_files
        Logger.debug('Loading current project files...')
        Instrument.instance.initialization_progress(phase: :load_project_files, message: 'Loading current project files')
        root_path && Actions::ReadProjectFiles.new(registry, root_path).run
      end
    end
  end
end
