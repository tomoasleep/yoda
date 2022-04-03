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

      delegate %i(get has_key? keys) => :view

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

      # @return [Registry::View]
      def view
        @view ||= Registry::View.new(composer: root_store, mask: registry_mask)
      end

      # @return [void]
      def reset_view
        @view = nil
      end

      private

      # @return [IdMask]
      def registry_mask
        IdMask.build({
          libraries.id => libraries.build_mask([project.dependency.core, project.dependency.std, *project.dependency.autoload_gems.select(&:installed?)]),
          local_store.id => nil,
        })
      end

      # @return [Registry::Composer]
      def root_store
        @root_store ||= Registry::Composer.new(id: :root, registries: [local_store.registry, libraries.registry])
      end

      def clear_cache
        view.clear_cache
      end
    end
  end
end
