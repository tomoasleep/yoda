require 'fileutils'
require 'bundler'
require 'tmpdir'
require 'digest'

module Yoda
  module Store
    class Project
      # Find registry file for the current project settings.
      class FileFinder
        attr_reader :project

        # @param project [Project]
        def initialize(project)
          @project = project
        end

        # @return [true, false]
        def present?
          File.exist?(cache_path)
        end

        # @return [String]
        def yoda_dir_path
          return nil unless project.root_path
          File.expand_path('.yoda', project.root_path)
        end

        # @return [String]
        def cache_dir_path
          return nil unless project.root_path
          File.expand_path('.yoda/cache', project.root_path)
        end

        # @return [String]
        def gemfile_lock_path
          return nil unless project.root_path
          File.absolute_path('Gemfile.lock', project.root_path)
        end

        # @return [String]
        def config_file_path
          return nil unless project.root_path
          File.absolute_path('.yoda.yml', project.root_path)
        end

        # @return [String, nil]
        def config_content
          config_file_path && File.exists?(config_file_path) && File.read(config_file_path)
        end

        def make_dir
          make_dir_at(cache_dir_path)
        end

        def clear_dir
          yoda_dir_path && File.exist?(yoda_dir_path) && FileUtils.rm_rf(yoda_dir_path)
        end

        private

        # @param dir_path [String]
        def make_dir_at(dir_path)
          dir_path && (File.exist?(dir_path) || FileUtils.mkdir_p(dir_path))
        end
      end
    end
  end
end
