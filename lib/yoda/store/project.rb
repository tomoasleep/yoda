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

      def initialize(root_path)
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
        parser = Bundler::LockfileParser.new(File.read(gemfile_lock_path))
        parser.specs.map { |gem| YARD::Registry.yardoc_file_for_gem(gem.name, gem.version) }.compact
      end

      def create_dependency_docs
        return unless File.exist?(gemfile_lock_path)
        parser = Bundler::LockfileParser.new(File.read(gemfile_lock_path))
        parser.specs.each do |gem|
          puts "Building gem docs for #{gem.name} #{gem.version}"
          YARD::CLI::Gems.run(gem.name, gem.version)
          puts "Done building gem docs for #{gem.name} #{gem.version}"
        end
      end

      def load_dependencies
        yardoc_files_of_dependencies.each { |yardoc_file| YardImporter.new.tap { |importer| importer.load(yardoc_file) }.import }
      end

      def load_project_files
        YARD::Registry.load(Dir.chdir(root_path) { Dir.glob("{lib,app}/**/*.rb\0ext/**/*.c") }, true)
      end

      def gemfile_lock_path
        File.absolute_path('Gemfile.lock', root_path)
      end

      def setup
        set_yardoc_file_path(self.class.tmpdir)
        load_dependencies
        load_project_files
      end
    end
  end
end
