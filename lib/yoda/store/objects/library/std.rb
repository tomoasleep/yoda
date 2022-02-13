module Yoda
  module Store
    module Objects
      module Library
        class Std
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
            'std'
          end

          def doc_path
            VersionStore.for_current_version.stdlib_yardoc_path
          end

          # @return [Connected]
          def with_project_connection(**kwargs)
            self.class.const_get(:Connected).new(self, **kwargs)
          end

          class Connected
            extend ConnectedDelegation
            include WithRegistry

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

            def create_patch
              Actions::ImportStdLibrary.run(self)
            end

            # @note Implementation for {WithRegistry#registry_path}
            def registry_path
              VersionStore.for_current_version.registry_path_for_stdlib
            end
          end
        end
      end
    end
  end
end
