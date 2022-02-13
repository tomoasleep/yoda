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

      attr_reader :project

      class << self
        # @param project [Project]
        def for_project(project)
          new(project)
        end
      end

      # @param project [Project]
      def initialize(project)
        fail TypeError, project unless project.is_a?(Project)
        @project = project
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
        @libraries ||= Registry::LibraryRegistrySet.new(project: project, adapter: adapter, on_change: -> { clear_cache })
      end

      # @return [LocalStore]
      def local_store
        @local_store ||= Registry::LocalStore.new(on_change: -> { clear_cache })
      end

      # @return [Adapters::Base]
      def adapter
        @adapter ||= begin
          Adapters.for(project.project_registry_path)
        end
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

      def clear_cache
        root_store.clear_cache
      end
    end
  end
end
