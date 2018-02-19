require 'bundler'
require 'tmpdir'
require 'fileutils'
require 'digest'

module Yoda
  module Store
    class Project
      # @type String
      attr_reader :root_path

      # @type Registry
      attr_reader :registry

      # @param root_path [String]
      def initialize(root_path)
        fail ArgumentError, root_path unless root_path.is_a?(String)

        @root_path = File.absolute_path(root_path)
        @registry = Registry.new
      end

      def clean
      end

      def setup
        YARD::Logger.instance(STDERR)
        make_dir
        cache.setup
        load_project_files
        self
      end

      def rebuild_cache(progress: false)
        make_dir
        cache.build(progress: progress)
      end

      # @param source_path [String]
      def read_source(source_path)
        Actions::ReadFile.run(registry, source_path)
      end

      def yoda_dir
        File.expand_path('.yoda', root_path)
      end

      private

      def make_dir
        File.exist?(yoda_dir) || FileUtils.mkdir(yoda_dir)
      end

      def load_project_files
        Actions::ReadProjectFiles.new(registry, root_path).run
      end

      def cache
        @cache ||= Cache.new(self)
      end

      class Cache
        class Builder
          # @return [Registry]
          attr_reader :registry

          # @return [String]
          attr_reader :root_path

          # @return [String]
          attr_reader :gemfile_lock_path

          def initialize(registry, root_path, gemfile_lock_path)
            @registry = registry
            @root_path = root_path
            @gemfile_lock_path = gemfile_lock_path
          end

          def run(progress: false)
            Actions::ImportCoreLibrary.new(registry).run
            if File.exist?(gemfile_lock_path)
              Actions::ImportGems.new(registry, gemfile_lock_parser.specs).run
            end
            registry.compress_and_save(progress: progress)
          end

          def gemfile_lock_parser
            Dir.chdir(root_path) do
              Bundler::LockfileParser.new(File.read(gemfile_lock_path))
            end
          end
        end

        # @return [Project]
        attr_reader :project

        def initialize(project)
          @project = project
        end

        def build(progress: false)
          STDERR.puts 'Constructing database for the current project.'
          YARD::Logger.instance(STDERR)
          make_cache_dir
          register_adapter
          project.registry.adapter.clear
          Builder.new(project.registry, project.root_path, gemfile_lock_path).run(progress: progress)
          STDERR.puts 'Finished to construct database for the current project.'
        end

        def setup
          if present?
            register_adapter
          else
            build
          end
        end

        private

        # @return [true, false]
        def present?
          File.exist?(cache_path)
        end

        def register_adapter
          return if project.registry.adapter
          project.registry.adapter = Adapters.default_adapter_class.for(cache_path)
        end

        def cache_dir
          File.expand_path('cache', project.yoda_dir)
        end

        def cache_name
          @cache_path ||= begin
            digest = Digest::SHA256.new
            digest.file(gemfile_lock_path) if File.exist?(gemfile_lock_path)
            digest.update(Yoda::VERSION)
            digest.update(Adapters.default_adapter_class.type.to_s)
            digest.hexdigest
          end
        end

        def cache_path
          File.expand_path(cache_name, cache_dir)
        end

        def make_cache_dir
          File.exist?(cache_dir) || FileUtils.mkdir_p(cache_dir)
        end

        def gemfile_lock_path
          File.absolute_path('Gemfile.lock', project.root_path)
        end
      end
    end
  end
end
