module Yoda
  module Store
    module Objects
      class LibrariesStatus
        include Serializable

        # @return [Array<CoreStatus, StdStatus, GemStatus, LocalLibraryStatus>]
        attr_reader :libraries

        # @param dependency [Project::Dependency]
        # @return [Array<Object::Library::Core, Object::Library::Std, Object::Library::Gem>]
        def self.libraies_from_dependency(dependency)
          [dependency.core, dependency.std, *dependency.gems.select(&:installed?)]
        end

        # @param libraries [Array<Library::Core, Library::Std, Library::Gem>]
        def initialize(libraries: [])
          @libraries = libraries
        end

        def add_library(library)
          @libraries.push(library)
        end

        def remove_library(library)
          @libraries.delete_if { |lib| lib.id == library.id }
        end

        def to_h
          { libraries: libraries }
        end

        # @return [Connected]
        def with_project_connection(**kwargs)
          self.class.const_get(:Connected).new(self, **kwargs)
        end

        class Connected
          extend ConnectedDelegation

          delegate_to_object :to_h, :with_project_connection, :add_library, :remove_library
          delegate_to_object :hash, :eql?, :==, :to_json, :derive

          attr_reader :object, :project

          # @param object [LibrariesStatus]
          # @param project [Project]
          def initialize(object, project:)
            @object = object
            @project = project
          end

          # @return [Array<Library::Core::Connected, Library::Std::Connected, Library::Gem::Connected>]
          def libraries
            object.libraries.map { |library| library.with_project_connection(project: project) }
          end


          # @return [Array<Registry::LibraryRegistry>]
          def registries
            libraries.map(&:registry).compact
          end
        end
      end
    end
  end
end
