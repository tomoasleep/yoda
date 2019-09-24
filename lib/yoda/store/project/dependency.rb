module Yoda
  module Store
    class Project
      class Dependency
        LOCAL_REGISTRY_ROOT = '~/.yoda/registry'

        attr_reader :project

        # @param project [Project]
        def initialize(project)
          @project = project
        end

        # @return [Array<Library>]
        def libraries
          builder.libraries
        end

        # @param name [String]
        # @param version [String]
        # @return [Library, nil]
        def gem_dependency(name:, version:)
          libraries.find { |library| library.name == name && library.version == version }
        end

        def core
          @core ||= Core.new
        end

        def std
          @std ||= Std.new
        end

        def builder
          @builder ||= Builder.new(project)
        end

        module WithRegistryPath
          def registry_path
            @registry_path ||= File.join(registry_dir_path, registry_name)
          end

          def registry_dir_path
            @registry_dir_path ||= global_registry_dir_path || local_registry_dir_path
          end

          private

          def registry_name
            @registry_name ||= begin
              digest = Digest::SHA256.new
              digest.update(RUBY_VERSION)
              digest.update(Project::REGISTRY_VERSION.to_s)
              digest.update(Adapters.default_adapter_class.type.to_s)
              digest.hexdigest
            end
          end

          def global_registry_dir_path
            nil
          end

          def local_registry_dir_path
            File.join(LOCAL_REGISTRY_ROOT, name, version)
          end
        end

        class Core
          include WithRegistryPath

          def id
            name
          end

          def name
            'core'
          end

          def version
            RUBY_VERSION
          end

          def doc_path
            File.expand_path("~/.yoda/sources/ruby-#{RUBY_VERSION}/.yardoc")
          end
        end

        class Std
          include WithRegistryPath

          def id
            name
          end

          def name
            'std'
          end

          def version
            RUBY_VERSION
          end

          def doc_path
            File.expand_path("~/.yoda/sources/ruby-#{RUBY_VERSION}/.yardoc-stdlib")
          end
        end

        class Library
          include WithRegistryPath
          
          # @return [Bundler::LazySpecification]
          attr_reader :spec

          # @param spec [Bundler::LazySpecification]
          def initialize(spec)
            @spec = spec
          end

          def id
            "#{name}:#{version}"
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

          def full_gem_path
            spec.full_gem_path
          end

          private

          def global_registry_dir_path
            doc_path = spec.doc_path
            base_path = File.dirname(doc_path)
            registry_path = spec.doc_path('.yoda')
            if File.writable?(doc_path) || (!File.directory?(doc_path) && File.writable?(base_path))
              registry_path
            end
          end
        end

        class Builder
          # @return [Project]
          attr_reader :project

          # @param project [Project]
          def initialize(project)
            @project = project
          end

          # @return [Array<Library>]
          def libraries
            @libraries ||= begin
              (gemfile_lock_parser&.specs || []).reject { |spec| self_spec?(spec) }.map { |spec| Library.new(spec) }
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
