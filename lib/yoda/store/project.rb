require 'bundler'
require 'tmpdir'
require 'fileutils'
require 'digest'

module Yoda
  module Store
    class Project
      attr_reader :root_path, :registry

      # @param root_path [String]
      def initialize(root_path)
        fail ArgumentError, root_path unless root_path.is_a?(String)

        @root_path = File.absolute_path(root_path)
        @registry = Registry.instance
      end

      def clean
        registry.clear
      end

      # @param path [String]
      def reparse(path)
        YARD.parse([path])
      end

      def load_project_files
        YARD.parse(project_files)
      end

      def setup
        YARD::Logger.instance(STDERR)
        prepare_database unless cache_store.has_cache?
        cache_store.load
        load_project_files
      end

      def prepare_database
        STDERR.puts 'Constructing database for the current project.'
        YARD::Logger.instance(STDERR)
        database_builder.build
        cache_store.save
        STDERR.puts 'Finished to construct database for the current project.'
      end

      def cache_store
        @cache_store ||= YodaCacheStore.new(self)
      end

      def database_builder
        @database_builder ||= DatabaseBuilder.new(self)
      end

      def project_files
        Dir.chdir(root_path) { Dir.glob("{lib,app}/**/*.rb\0ext/**/*.c\0.yoda/*.rb").map { |name| File.expand_path(name, root_path) } }
      end

      def yoda_dir
        File.expand_path('.yoda', root_path)
      end

      def make_dir
        File.exist?(yoda_dir) || FileUtils.mkdir(yoda_dir)
      end

      def gemfile_lock_path
        File.absolute_path('Gemfile.lock', root_path)
      end

      class DatabaseBuilder
        attr_reader :project
        def initialize(project)
          @project = project
        end

        def build
          create_dependency_docs
          load_core
          load_dependencies
        end

        def gemfile_lock_parser
          return unless File.exist?(project.gemfile_lock_path)
          Dir.chdir(project.root_path) do
            Bundler::LockfileParser.new(File.read(project.gemfile_lock_path))
          end
        end

        def create_dependency_docs
          return unless File.exist?(project.gemfile_lock_path)
          gemfile_lock_parser.specs.each do |gem|
            STDERR.puts "Building gem docs for #{gem.name} #{gem.version}"
            begin
              Thread.new do
                YARD::CLI::Gems.run(gem.name, gem.version)
              end.join
              STDERR.puts "Done building gem docs for #{gem.name} #{gem.version}"
            rescue => ex
              STDERR.puts ex
              STDERR.puts ex.backtrace
              STDERR.puts "Failed to build #{gem.name} #{gem.version}"
            end
          end
        end

        def yardoc_files_of_dependencies
          return [] unless File.exist?(project.gemfile_lock_path)
          gemfile_lock_parser.specs.map { |gem| YARD::Registry.yardoc_file_for_gem(gem.name, gem.version) }.compact
        rescue Bundler::BundlerError => ex
          STDERR.puts ex
          STDERR.puts ex.backtrace
          []
        end

        def load_core
          core_doc_files.each { |yardoc_file| YardImporter.import(yardoc_file) }
        end

        def load_dependencies
          yardoc_files_of_dependencies.each do |yardoc_file|
            begin
              YardImporter.import(yardoc_file)
            rescue => ex
              STDERR.puts ex
              STDERR.puts ex.backtrace
              STDERR.puts "Failed to load #{yardoc_file}"
            end
          end
        end

        def core_doc_files
          %w(core/ruby-2.5.0/.yardoc core/ruby-2.5.0/.yardoc-stdlib).map { |path| File.expand_path(path, File.expand_path('../../../', __dir__)) }.select { |path| File.exist?(path) }
        end
      end

      class YodaCacheStore
        attr_reader :project
        def initialize(project)
          @project = project
        end

        def cache_dir
          File.expand_path('cache', project.yoda_dir)
        end

        def cache_name
          @cache_path ||= File.exist?(project.gemfile_lock_path) ? Digest::SHA256.file(project.gemfile_lock_path).hexdigest : 'core'
        end

        def cache_path
          File.expand_path(cache_name, cache_dir)
        end

        def has_cache?
          File.exist?(cache_path)
        end

        def save
          make_cache_dir
          project.registry.save(cache_path)
        end

        def load
          return unless has_cache?
          project.registry.load(cache_path)
        end

        def make_cache_dir
          project.make_dir
          File.exist?(cache_dir) || FileUtils.mkdir(cache_dir)
        end
      end
    end
  end
end
