require 'forwardable'

module Yoda
  module Store
    class Registry::ProjectRegistry
      extend Forwardable
      include HasServices

      service(:constant_finder) { Query::FindConstant.new(self) }
      service(:meta_class_finder) { Query::FindMetaClass.new(self) }
      service(:method_finder) { Query::FindMethod.new(self) }
      service(:signature_finder) { Query::FindSignature.new(self) }

      delegate %i(get has_key? keys) => :root_store

      PROJECT_STATUS_KEY = '%project_status'
      LIBRARY_STORE_INDEX_KEY = '%library_store_index'

      class << self
        # @param project [Project]
        def for_project(project)
          path = File.expand_path(project.registry_name, project.cache.cache_dir_path)
          new(Adapters.for(path))
        end
      end

      def initialize(adapter)
        fail TypeError, adapter unless adapter.is_a?(Adapters::Base)
        @adapter = adapter
      end

      def root_store
        @root_store ||= begin
          Registry::Cache::RegistryWrapper.new(
            Registry::Composer.new(id: :root, registries: [local_store, library_store])
          )
        end
      end

      def modify_library_registries(add:, remove:)
        add.each do |library|
          root_store.clear_cache
          library_store.add_registry(registry)
        end
        remove.each do |library|
          root_store.clear_cache
          library_store.remove_registry(registry)
        end
        save
      end

      def add_library_registry(registry)
        root_store.clear_cache
        library_store.add_registry(registry)
        save
      end

      def remove_library_registry(registry)
        root_store.clear_cache
        library_store.remove_registry(registry)
        save
      end

      # @param patch [Objects::Patch]
      def add_file_patch(patch)
        root_store.clear_cache
        local_store.add_registry(patch)
      end

      # @return [ProjectStatus]
      def project_status
        @project_status ||= adapter.get(PROJECT_STATUS_KEY) || Objects::ProjectStatus.new
      end

      private

      # @return [Adapters::LmdbAdapter, nil]
      attr_reader :adapter

      def local_store
        @local_store ||= begin
          Registry::Index::ComposerWrapper.new(composer: Registry::Composer.new(id: :local), index: Registry::Index.new)
        end
      end

      def library_store
        @library_store ||= begin
          library_composer = Registry::Composer.new(id: :library)
          Registry::Index::ComposerWrapper.new(composer: library_composer, index: library_store_index)
        end
      end

      def library_store_index
        @library_store_index ||= adapter.get(LIBRARY_STORE_INDEX_KEY) || Registry::Index.new
      end

      def save
        adapter.put(PROJECT_STATUS_KEY, project_statue_key)
        adapter.put(GEM_INDEX_KEY, library_store_index)
      end

      def inspect
        "#<#{self.class.name}: @adapter=#{adapter.inspect}>"
      end
    end
  end
end
