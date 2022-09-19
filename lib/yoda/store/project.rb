require 'fileutils'
require 'forwardable'
require 'pathname'

module Yoda
  module Store
    class Project
      require 'yoda/store/project/file_finder'
      require 'yoda/store/project/dependency'
      require 'yoda/store/project/setuper'
      require 'yoda/store/project/rbs_loader'

      extend Forwardable

      class << self
        # @param name [String]
        # @param root_path [String, nil]
        def for_path(root_path, name: nil)
          file_tree = FileTree.new(base_path: root_path)
          name ||= root_path ? File.basename(root_path) : "root"
          new(name: name, file_tree: file_tree)
        end

        def temporal(name: "temporal")
          new(name: name, file_tree: FileTree.new(base_path: nil))
        end
      end

      delegate(
        [
          :yoda_dir_path,
          :cache_dir_path,
          :library_registry_dir_path,
          :gemfile_lock_path,
          :config_file_path,
          :project_source_paths,
          :project_load_paths,
          :readable_config_file_path,
          :library_local_yardoc_path,
          :library_registry_path,
          :project_registry_path,
        ] => :file_finder,
      )

      delegate [:rbs_environment] => :rbs_loader
      delegate [:clear, :reset] => :setuper

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
      def rbs_loader
        @rbs_loader ||= RbsLoader.new(self)
      end

      # @return [Model::Environment]
      def environment
        @environment ||= Model::Environment.from_project(self)
      end

      # @param controller [Server::ServerController, nil]
      def setup(rebuild: false, controller: nil)
        setuper.run(rebuild: rebuild, controller: controller)
      end

      # @return [Services::Catalog]
      def service_catalog
        Services::Catalog.new(environment: environment)
      end

      # @return [Config]
      def config
        @config ||= begin
          if readable_config_file_path
            Config.at(readable_config_file_path)
          else
            Config.from_yaml_data('')
          end
        end
      end

      # @return [FileFinder]
      def file_finder
        @file_finder ||= FileFinder.new(self)
      end

      private

      def setuper
        Setuper.new(self)
      end

      def register_file_tree_events
        file_tree.on_change do |path:, content:|
          if content
            handle_file_changed_event(path: path, content: content)
          else
            handle_file_deleted_event(path: path)
          end
        end
      end

      def handle_file_changed_event(path:, content:)
        if %w(.rb .c).include?(File.extname(path))
            Actions::ReadFile.new(path, content: content).run_process_and_register(registry)
        end

        if %w(Gemfile Gemfile.lock).include?(File.basename(path))
          setup
        end
      end

      def handle_file_deleted_event(path:)
        unread_source(path)
      end

      # @param source_path [String]
      def unread_source(source_path)
        patch = registry.local_store.find_file_patch(Actions::ReadFile.patch_id_for_file(source_path))
        registry.local_store.remove_file_patch(patch) if patch
      end

      def on_memory?
        !root_path
      end
    end
  end
end
