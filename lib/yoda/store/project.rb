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

        @root_path = root_path
        @registry = Registry.instance
        at_exit { clean }
      end

      def clean
        unless @cleaned
          @cleaned = true
          YARD::Registry.clear
          FileUtils.remove_entry_secure(tmpdir)
        end
      end

      # @param path [String]
      def reparse(path)
        YARD.parse([path])
      end

      def load_project_files
        YARD.parse(project_files)
      end

      def project_files
        Dir.chdir(root_path) { Dir.glob("{lib,app}/**/*.rb\0ext/**/*.c").map { |name| File.expand_path(name, root_path) } }
      end

      def setup
        YARD::Logger.instance(STDERR)
        prepare_database unless File.exist?(database_path)
        load_database
        load_project_files
      end

      def prepare_database
        STDERR.puts 'Constructing database for the current project.'
        YARD::Logger.instance(STDERR)
        YodaDataBaseCreation.new(self).run
        STDERR.puts 'Finished to construct database for the current project.'
      end

      class YodaDataBaseCreation
        attr_reader :project
        def initialize(project)
          @project = project
        end

        def run
          create_dependency_docs
          load_core
          load_dependencies
          save_database
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

        def save_database
          make_database_dir unless File.exist?(project.database_dir)
          YARD::Registry.save(false, project.database_path)
        end

        def make_database_dir
          File.exist?(project.database_dir) || FileUtils.mkdir(project.database_dir)
        end
      end

      def load_database
        return unless File.exist?(database_path)
        YARD::Registry.load_yardoc(database_path)
      end

      def tmpdir
        @tmpdir ||= begin
          Dir.mktmpdir('yoda')
        end
      end

      def database_dir
        File.expand_path('.yoda', root_path)
      end

      def database_path
        File.expand_path(database_name, database_dir)
      end

      def database_name
        @database_name ||= File.exist?(gemfile_lock_path) ? Digest::SHA256.file(gemfile_lock_path).hexdigest : 'core'
      end

      def gemfile_lock_path
        File.absolute_path('Gemfile.lock', root_path)
      end
    end
  end
end
