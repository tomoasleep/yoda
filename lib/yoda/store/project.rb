require 'bundler'

module Yoda
  module Store
    class Project
      attr_reader :root_path

      def initialize(root_path)
        @root_path = root_path
      end

      def set_yardoc_file_path(path)
        YARD::Registry.yardoc_file = path
      end

      def yardoc_files_of_dependencies
        return [] unless File.exist?(gemfile_lock_path)
        parser = Bundler::LockfileParser.new(File.read(gemfile_lock_path))
        parser.specs.map { |gem| YARD::Registry.yardoc_file_for_gem(gem.name, gem.version) }.compact
      end

      def load_dependencies
        yardoc_files_of_dependencies.each { |yardoc_file| YardImporter.new.tap { |importer| importer.load(yardoc_file) }.import }
      end

      def load_project_files
      end

      def gemfile_lock_path
        File.absolute_path('Gemfile.lock', root_path)
      end
    end
  end
end
