require 'fileutils'
require 'bundler'
require 'tmpdir'
require 'digest'

module Yoda
  module Store
    class Project
      # Find registry file for the current project settings.
      class Cache
        class << self
          # @param project_dir [String]
          # @return [String]
          def cache_dir(project_dir)
            File.expand_path('.yoda/cache', project_dir)
          end

          # @param project_dir [String]
          # @return [String]
          def gemfile_lock_path(project_dir)
            File.absolute_path('Gemfile.lock', project_dir)
          end

          # @param project [Project]
          def build_for(project)
            new(cache_dir_path: cache_dir(project.root_path), gemfile_lock_path: gemfile_lock_path(project.root_path))
          end
        end

        # @return [String]
        attr_reader :cache_dir_path

        # @return [String, nil]
        attr_reader :gemfile_lock_path

        # @param cache_dir_path [String]
        # @param gemfile_lock_path [String, nil]
        def initialize(cache_dir_path:, gemfile_lock_path: nil)
          @cache_dir_path = cache_dir_path
          @gemfile_lock_path = gemfile_lock_path
          make_cache_dir
        end

        # @return [true, false]
        def present?
          File.exist?(cache_path)
        end

        private

        def make_cache_dir
          File.exist?(cache_dir_path) || FileUtils.mkdir_p(cache_dir_path)
        end
      end
    end
  end
end
