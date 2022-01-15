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
      PERSISTABLE_LIBRARY_STORE_INDEX_KEY = '%persistable_library_store_index'

      class << self
        # @param project [Project]
        def for_project(project)
          path = project.root_path && File.expand_path(project.registry_name, project.cache_dir_path)
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
            Registry::Composer.new(id: :root, registries: [local_store, persistable_library_store, volatile_library_store]),
          )
        end
      end

      def modify_libraries(add:, remove:)
        remove.each do |library|
          if registry = library.registry
            persistable_library_store.remove_registry(registry)
            volatile_library_store.remove_registry(registry)
            project_status.libraries.delete(library)
          end
        end
        add.each do |library|
          if registry = library.registry
            if registry.persistable?
              persistable_library_store.add_registry(registry)
            else
              volatile_library_store.add_registry(registry)
            end
            project_status.libraries.push(library)
          end
        end
        root_store.clear_cache
        save
      end

      def add_library(library)
        add_library_registry(library.registry)
        project_status.libraries.push(library)
        save
      end

      def remove_library(library)
        remove_library_registry(library.registry)
        project_status.libraries.delete(library)
        save
      end

      def add_library_registry(registry)
        root_store.clear_cache
        if registry.persistable?
          persistable_library_store.add_registry(registry)
        else
          volatile_library_store.add_registry(registry)
        end

        save
      end

      def remove_library_registry(registry)
        root_store.clear_cache
        persistable_library_store.remove_registry(registry)
        volatile_library_store.remove_registry(registry)
        save
      end

      # @param patch [Objects::Patch]
      def add_file_patch(patch)
        root_store.clear_cache
        local_store.add_registry(patch)
      end

      # @return [Objects::ProjectStatus]
      def project_status
        @project_status ||= adapter.get(PROJECT_STATUS_KEY) || Objects::ProjectStatus.new
      end
      
      def local_store
        @local_store ||= Registry::Index.new.wrap(Registry::Composer.new(id: :local))
      end

      private

      # @return [Adapters::LmdbAdapter, nil]
      attr_reader :adapter

      def persistable_library_store
        @persistable_library_store ||= begin
          library_composer = Registry::Composer.new(id: :persistable_library, registries: project_status.registries.select(&:persistable?))
          persistable_library_store_index.wrap(library_composer)
        end
      end

      def persistable_library_store_index
        @persistable_library_store_index ||= Registry::Index.new(content: persistable_library_store_index_content, registry_ids: project_status.libraries.map(&:id))
      end

      def persistable_library_store_index_content
        @persistable_library_store_index_content ||= Objects::Map.new(path: PERSISTABLE_LIBRARY_STORE_INDEX_KEY, adapter: adapter)
      end

      def volatile_library_store
        @volatile_library_store ||= begin
          Registry::Composer.new(id: :volatile_library, registries: project_status.registries.reject(&:persistable?))
        end
      end

      def save
        persistable_library_store_index_content.save
        adapter.put(PROJECT_STATUS_KEY, project_status)
      end

      def inspect
        "#<#{self.class.name}: @adapter=#{adapter.inspect}>"
      end
    end
  end
end
