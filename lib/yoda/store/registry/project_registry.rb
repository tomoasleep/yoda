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

      class << self
        # @param project [Project]
        def for_project(project)
          path = project.root_path && File.expand_path(project.registry_name, project.cache_dir_path)
          new(Adapters.for(path))
        end
      end

      # @param adapter [Adapters::Base]
      def initialize(adapter)
        fail TypeError, adapter unless adapter.is_a?(Adapters::Base)
        @adapter = adapter
      end

      def root_store
        @root_store ||= begin
          Registry::Cache::RegistryWrapper.new(
            Registry::Composer.new(id: :root, registries: [local_store.registry, libraries.registry]),
          )
        end
      end

      # @return [LibraryRegistrySet]
      def libraries
        @libraries ||= Registry::LibraryRegistrySet.new(adapter, on_change: -> { clear_cache })
      end

      # @return [LocalStore]
      def local_store
        @local_store ||= Registry::LocalStore.new(on_change: -> { clear_cache })
      end

      # @param pp [PP]
      def pretty_print(pp)
        pp.object_group(self) do
          pp.breakable
          pp.text "@adapter="
          pp.pp adapter
        end
      end

      private

      # @return [Adapters::Base, nil]
      attr_reader :adapter

      def clear_cache
        root_store.clear_cache
      end
    end
  end
end
