require 'yoda/store/objects/library/path_resolvable'

module Yoda
  module Store
    module Objects
      module Library
        class Core
          include Serializable

          # @return [String]
          attr_reader :version

          # @return [Core]
          def self.current_version
            new
          end

          # @param version [String]
          def initialize(version: RUBY_VERSION)
            @version = version
          end

          def to_h
            { version: version }
          end

          def id
            name
          end

          def name
            'core'
          end

          def doc_path
            VersionStore.for_current_version.core_yardoc_path
          end

          # @return [Connected]
          def with_project_connection(**kwargs)
            self.class.const_get(:Connected).new(self, **kwargs)
          end

          class Connected
            extend ConnectedDelegation
            include WithRegistry
            include PathResolvable

            delegate_to_object :version
            delegate_to_object :id, :name, :doc_path, :to_h, :with_project_connection
            delegate_to_object :hash, :eql?, :==, :to_json, :derive

            attr_reader :object, :project

            # @param object [Core]
            # @param project [Project]
            def initialize(object, project:)
              @object = object
              @project = project
            end

            # @return [Objects::PatchSet]
            # @raise [Actions::ImportError]
            def create_patch
              Objects::PatchSet.new(Actions::ImportCoreLibrary.run(self))
            end

            # @note Implementation for {WithRegistry#registry_path}
            def registry_path
              VersionStore.for_current_version.registry_path_for_core
            end

            # @return [Array<String>]
            def require_paths
              []
            end
          end
        end
      end
    end
  end
end
