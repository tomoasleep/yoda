module Yoda
  module Store
    class Project
      class Dependency
        LOCAL_REGISTRY_ROOT = File.expand_path('~/.yoda/registry')

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
          @core ||= Objects::Library::Core.current_version
        end

        def std
          @std ||= Objects::Library::Std.current_version
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
              (gemfile_lock_parser&.specs || []).reject { |spec| self_spec?(spec) }.map { |spec| Objects::Library::Gem.from_gem_spec(spec) }
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
