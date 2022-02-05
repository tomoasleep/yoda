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

      class << self
        # @param name [String]
        # @param root_path [String, nil]
        def for_path(root_path, name: nil)
          file_tree = FileTree.new(base_path: root_path)
          name ||= root_path ? File.basename(root_path) : "root"
          new(name: name, file_tree: file_tree)
        end
      end

      delegate [:cache_dir_path, :yoda_dir_path, :gemfile_lock_path] => :files

      # @return [FileTree]
      attr_reader :file_tree

      # @return [String]
      attr_reader :name

      # @param name [String]
      # @param file_tree [FileTree]
      def initialize(name:, file_tree:)
        @name = name
        @file_tree = file_tree
        register_file_tree_events
      end

      # @return [String, nil]
      def root_path
        file_tree.base_path
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

      # @return [Array<BaseError>]
      def setup
        files.make_dir
        errors = import_project_dependencies
        rbs_environment
        load_project_files
        errors
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

      def registry_name
        @registry_name ||= Registry.registry_name
      end

      private

      def register_file_tree_events
        file_tree.on_change do |path:, content:|
          if content
            Actions::ReadFile.run(registry, path, content: content)
          else
            unread_source(path)
          end
        end
      end

      # @param source_path [String]
      def unread_source(source_path)
        patch = registry.local_store.find_file_patch(Actions::ReadFile.patch_id_for_file(source_path))
        registry.local_store.remove_file_patch(patch) if patch
      end

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
