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

        def core
          @core ||= Objects::Library.core
        end

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
            @libraries ||= begin
              (gem_specs || []).reject { |spec| self_spec?(spec) || metadata?(spec) }.reject { |spec| project.config.ignored_gems.include?(spec.name) }.map { |spec| Objects::Library::Gem.from_gem_spec(spec) }
            end
          end

          private

          # @return [Bundler::SpecSet, nil]
          def gem_specs
            @gem_specs ||= begin
              return if !project.gemfile_lock_path || !File.exists?(project.gemfile_lock_path)
              Dir.chdir(project.root_path) do
                Bundler.definition.specs
              end
            end
          end

          # @param [Gem::Specification]
          def metadata?(spec)
            spec.source.is_a?(Bundler::Source::Metadata)
          end

          def self_spec?(spec)
            spec.source.is_a?(Bundler::Source::Path) && (File.expand_path(spec.source.path) == File.expand_path(project.root_path))
          end
        end
      end
    end
  end
end
