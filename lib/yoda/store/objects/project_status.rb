module Yoda
  module Store
    module Objects
      class ProjectStatus
        include Serializable

        # @return [Array<CoreStatus, StdStatus, GemStatus, LocalLibraryStatus>]
        attr_reader :libraries

        # @param dependency [Project::Dependency]
        def self.libraies_from_dependency(dependency)
          [dependency.core, dependency.std, *dependency.gems]
        end

        # @param bundle [Array<Library::Core, Library::Std, Library::Gem>]
        def initialize(libraries: [])
          @libraries = libraries
        end

          # @return [Array<Registry::LibraryRegistry>]
          def registries
            libraries.map(&:registry).compact
          end

        def to_h
          { libraries: libraries }
        end
      end
    end
  end
end
