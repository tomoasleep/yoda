module Yoda
  module Store
    module Registry
      class LibraryRegistrySet
        STATUS_KEY = '%library_status'
        PERSISTABLE_LIBRARY_STORE_INDEX_KEY = '%persistable_library_store_index'

        # @return [Project]
        attr_reader :project

        # @return [Adapters::Base]
        attr_reader :adapter
        private :adapter

        # @return [Proc, nil]
        attr_reader :on_change

        # @param project [Project]
        # @param adapter [Adapters::Base]
        # @param on_change [Proc, nil]
        def initialize(project:, adapter:, on_change: nil)
          fail TypeError, adapter unless adapter.is_a?(Adapters::Base)
          @project = project
          @adapter = adapter
          @on_change = on_change
        end

        # @return [Registry::Composer]
        def registry
          Registry::Composer.new(id: :libraries, registries: [persistable_library_store, volatile_library_store])
        end

        # @param add [Array<Objects::Library::Core, Objects::Library::Gem, Objects::Library::Std>]
        # @param remove [Array<Objects::Library::Core, Objects::Library::Gem, Objects::Library::Std>]
        def modify(add:, remove:)
          add = add.map { |library| library.with_project_connection(project: project) }
          remove = remove.map { |library| library.with_project_connection(project: project) }

          remove.each do |library|
            if registry = library.registry
              persistable_library_store.remove_registry(registry)
              volatile_library_store.remove_registry(registry)
              status.remove_library(library)
            end
          end
          add.each do |library|
            if registry = library.registry
              if registry.persistable?
                persistable_library_store.add_registry(registry)
              else
                volatile_library_store.add_registry(registry)
              end
              status.add_library(library)
            end
          end
          on_change&.call
          save
        end

        # @param library [Library::Core, Library::Std, Library::Gem]
        def add(library)
          library = library.with_project_connection(project: project)
          add_library_registry(library.registry)
          status.add_library(library)
          save
        end

        # @param library [Library::Core, Library::Std, Library::Gem]
        def remove(library)
          library = library.with_project_connection(project: project)
          remove_library_registry(library.registry)
          status.remove_library(library)
          save
        end

        # @return [Objects::LibrariesStatus::Connected]
        def status
          @status ||= (adapter.get(STATUS_KEY) || Objects::LibrariesStatus.new).with_project_connection(project: project)
        end

        def save
          persistable_library_store_index_content.save
          adapter.put(STATUS_KEY, status)
        end

        private

        def add_library_registry(registry)
          if registry.persistable?
            persistable_library_store.add_registry(registry)
          else
            volatile_library_store.add_registry(registry)
          end

          on_change&.call
          save
        end

        def remove_library_registry(registry)
          persistable_library_store.remove_registry(registry)
          volatile_library_store.remove_registry(registry)
          on_change&.call
          save
        end

        def persistable_library_store
          @persistable_library_store ||= begin
            library_composer = Registry::Composer.new(id: :persistable_library, registries: status.registries.select(&:persistable?))
            persistable_library_store_index.wrap(library_composer)
          end
        end

        def persistable_library_store_index
          @persistable_library_store_index ||= Registry::Index.new(content: persistable_library_store_index_content, registry_ids: status.libraries.map(&:id))
        end

        def persistable_library_store_index_content
          @persistable_library_store_index_content ||= Objects::Map.new(path: PERSISTABLE_LIBRARY_STORE_INDEX_KEY, adapter: adapter)
        end

        def volatile_library_store
          @volatile_library_store ||= begin
            Registry::Composer.new(id: :volatile_library, registries: status.registries.reject(&:persistable?))
          end
        end

        def inspect
          "#<#{self.class.name}: @adapter=#{adapter.inspect}>"
        end
      end
    end
  end
end
