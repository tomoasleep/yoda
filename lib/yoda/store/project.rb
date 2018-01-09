require 'bundler'
require 'tmpdir'
require 'fileutils'

module Yoda
  module Store
    class Project
      attr_reader :root_path

      def self.tmpdir
        @tmpdir ||= begin
          dir = Dir.mktmpdir('yoda')
          at_exit { FileUtils.remove_entry_secure(dir) }
          dir
        end
      end

      # @param root_path [String]
      def initialize(root_path)
        fail ArgumentError, root_path unless root_path.is_a?(String)
        @root_path = root_path
      end

      def registry
        @registry ||= Registry.instance
      end

      def set_yardoc_file_path(path)
        YARD::Registry.yardoc_file = path
      end

      def yardoc_files_of_dependencies
        return [] unless File.exist?(gemfile_lock_path)
        Dir.chdir(root_path) do
          parser = Bundler::LockfileParser.new(File.read(gemfile_lock_path))
          parser.specs.map { |gem| YARD::Registry.yardoc_file_for_gem(gem.name, gem.version) }.compact
        end
      rescue Bundler::BundlerError => ex
        STDERR.puts ex
        STDERR.puts ex.backtrace
        []
      end

      def create_dependency_docs
        return unless File.exist?(gemfile_lock_path)
        parser = Bundler::LockfileParser.new(File.read(gemfile_lock_path))
        parser.specs.each do |gem|
          STDERR.puts "Building gem docs for #{gem.name} #{gem.version}"
          YARD::CLI::Gems.run(gem.name, gem.version)
          STDERR.puts "Done building gem docs for #{gem.name} #{gem.version}"
        end
      end

      def load_dependencies
        yardoc_files_of_dependencies.each { |yardoc_file| YardImporter.new.tap { |importer| importer.load(yardoc_file) }.import }
      end

      def project_files
        Dir.chdir(root_path) { Dir.glob("{lib,app}/**/*.rb\0ext/**/*.c").map { |name| File.expand_path(name, root_path) } }
      end

      def core_doc_files
        %w(core/ruby-2.5.0/.yardoc core/ruby-2.5.0/.yardoc-stdlib).map { |path| File.expand_path(path, File.expand_path('../../../', __dir__)) }.select { |path| File.exist?(path) }
      end

      def load_core
        core_doc_files.each { |yardoc_file| YardImporter.new.tap { |importer| importer.load(yardoc_file) }.import }
      end

      # @param path [String]
      def reparse(path)
        YARD.parse([path])
      end

      def load_project_files
        YARD.parse(project_files)
      end

      def gemfile_lock_path
        File.absolute_path('Gemfile.lock', root_path)
      end

      def setup
        YARD::Logger.instance(STDERR)
        set_yardoc_file_path(self.class.tmpdir)
        load_core
        load_dependencies
        load_project_files
      end
    end
  end
end
