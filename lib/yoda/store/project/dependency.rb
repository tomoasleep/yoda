require 'open3'

module Yoda
  module Store
    class Project
      class Dependency
        attr_reader :project

        # @param project [Project]
        def initialize(project)
          @project = project
        end

        # @return [Array<Objects::Library::Gem>]
        def gems
          builder.gems
        end

        # @param name [String]
        # @param version [String]
        # @return [Library, nil]
        def gem_dependency(name:, version:)
          libraries.find { |library| library.name == name && library.version == version }
        end

        # @return [Objects::Library::Core]
        def core
          @core ||= Objects::Library.core
        end

        # @return [Objects::Library::Std]
        def std
          @std ||= Objects::Library.std
        end

        def builder
          @builder ||= Builder.new(project)
        end

        class Builder
          # @return [Project]
          attr_reader :project

          # @param project [Project]
          def initialize(project)
            @project = project
          end

          # @return [Array<Objects::Library::Gem>]
          def gems
            @gems ||= begin
              dependencies
                .map { |attrs| Objects::Library::Gem.new(**attrs) }
                .reject { |spec| project.config.ignored_gems.include?(spec.name) }
            end
          end

          private

          # @return [Array<Hash>]
          def dependencies
            analyzed_deps[:dependencies] || []
          end

          # @return [Hash]
          def analyzed_deps
            @analyzed_deps ||= begin
              return {} unless project.root_path

              # Bundler pollutes environment variables in the current process, so analyze in another process.
              stdout, stderr, status = Open3.capture3(Yoda::Cli.yoda_exe, "analyze-deps", project.root_path)

              fail stderr unless status.success?

              Logger.trace("Analysis Result: #{stdout}")
              JSON.parse(stdout, symbolize_names: true)
            end
          end
        end
      end
    end
  end
end
