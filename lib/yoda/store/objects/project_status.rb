module Yoda
  module Store
    module Objects
      class ProjectStatus
        include Serializable

        # @return [Array<CoreStatus, StdStatus, GemStatus, LocalLibraryStatus>]
        attr_reader :libraries

        # @param dependency [Project::Dependency]
        def self.libraies_from_dependency(dependency)
          dependency.libraries.map do |dependency|
            if dependency.gem?
              GemStatus.from_gem_specification(dependency.spec)
            else
              LocalLibraryStatus.from_dependency(dependency)
            end
          end + [dependency.core, dependency.std]
        end

        # @param bundle [BundleStatus]
        def initialize(libraries: [])
          @libraries = libraries
        end

        def to_h
          { libraries: libraries }
        end

        class CoreStatus
          include Serializable

          # @return [String]
          attr_reader :version

          # @return [StdStatus]
          def self.current_version
            new(version: RUBY_VERSION)
          end

          # @param version [String]
          def initialize(version:)
            @version = version
          end

          def to_h
            { version: version }
          end
        end

        # Remember ruby core and standard library state
        class StdStatus
          include Serializable
          # @return [String]
          attr_reader :version

          # @return [StdStatus]
          def self.current_version
            new(version: RUBY_VERSION)
          end

          # @param version [String]
          def initialize(version:)
            @version = version
          end

          def to_h
            { version: version }
          end
        end

        class LocalLibraryStatus
          include Serializable
          # @return [String]
          attr_reader :name, :path

          # @param deps [Dependency::Library]
          # @return [GemStatus]
          def self.from_dependency(deps)
            new(name: deps.name, path: deps.source_path)
          end

          def initialize(name:, path:)
            @name = name
            @path = path
          end

          def to_h
            { name: name, path: path }
          end
        end

        # Remember each gem state
        class GemStatus
          include Serializable
          # @return [String]
          attr_reader :name, :version

          # @param gem [Bundler::LazySpecification]
          # @return [GemStatus]
          def self.from_gem_specification(gem)
            new(name: gem.name, version: gem.version)
          end

          # @param name [String]
          # @param version [String]
          # @param present [true, false] represents the flag if the specified gem's index file is present.
          def initialize(name:, version:)
            @name = name
            @version = version
          end

          def to_h
            { name: name, version: version }
          end
        end
      end
    end
  end
end
