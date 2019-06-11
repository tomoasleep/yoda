module Yoda
  module Store
    class Project
      class Dependency
        # @param project [Project]
        # @return [Array<Dependency>]
        def self.build_for_project(project)
          Builder.new(project).dependencies
        end

        # @return [Bundler::LazySpecification]
        attr_reader :spec

        # @param spec [Bundler::LazySpecification]
        def initialize(spec)
          @spec = spec
        end

        def name
          spec.name
        end

        def version
          spec.version
        end

        def gem?
          !source_path
        end

        def source_path
          spec.source.respond_to?(:path) ? spec.source.path : nil
        end

        class Builder
          # @return [Project]
          attr_reader :project

          # @param project [Project]
          def initialize(project)
            @project = project
          end

          # @return [Array<Dependency>]
          def dependencies
            @gem_specs ||= begin
              (gemfile_lock_parser&.specs || []).reject { |spec| self_spec?(spec) }.map { |spec| Dependency.new(spec) }
            end
          end

          private

          # @return [Bundler::LockfileParser, nil]
          def gemfile_lock_parser
            @gemfile_lock_parser ||= begin
              return if !gemfile_lock_path || !File.exists?(gemfile_lock_path)
              Dir.chdir(root_path) do
                Bundler::LockfileParser.new(File.read(gemfile_lock_path))
              end
            end
          end

          def gemfile_lock_path
            Cache.gemfile_lock_path(root_path)
          end

          def root_path
            project.root_path
          end

          def self_spec?(spec)
            spec.source.is_a?(Bundler::Source::Path) && (File.expand_path(spec.source.path) == File.expand_path(root_path))
          end
        end
      end
    end
  end
end
