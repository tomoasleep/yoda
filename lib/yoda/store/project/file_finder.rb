require 'fileutils'
require 'tmpdir'

module Yoda
  module Store
    class Project
      # Find registry file for the current project settings.
      class FileFinder
        # @return [Project]
        attr_reader :project

        # @param project [Project]
        def initialize(project)
          @project = project
        end

        # @return [true, false]
        def present?
          File.exist?(cache_path)
        end

        # @return [String, nil]
        def yoda_dir_path
          expand_path('.yoda')
        end

        # @return [String, nil]
        def cache_dir_path
          expand_path('.yoda/cache')
        end

        # @return [String, nil]
        def library_registry_dir_path
          expand_path(File.join('.yoda', 'library_registry'))
        end

        # @return [String, nil]
        def library_local_yardoc_dir_path
          expand_path(File.join('.yoda', 'yardoc', RUBY_VERSION))
        end

        # @return [String, nil]
        def gemfile_lock_path
          expand_path('Gemfile.lock')
        end

        # @return [String, nil]
        def config_file_path
          expand_path('.yoda.yml')
        end

        # @return [String, nil]
        def readable_config_file_path
          path = config_file_path
          path && File.readable?(config_file_path) ? path : nil
        end

        # @param name [String]
        # @param version [String]
        # @return [String, nil]
        def library_local_yardoc_path(name:, version:)
          expand_path("#{name}-#{version}.yardoc", library_local_yardoc_dir_path)
        end

        # @param name [String]
        # @param version [String]
        # @return [String, nil]
        def library_registry_path(name:, version:)
          expand_path(Registry.registry_name, library_registry_dir_path)
        end

        # @return [String, nil]
        def project_registry_path
          expand_path(Registry.registry_name, cache_dir_path)
        end

        def make_dir
          make_dir_at(cache_dir_path)
          make_dir_at(library_local_yardoc_dir_path)
          make_dir_at(library_registry_dir_path)
        end

        def clear_dir
          yoda_dir_path && File.exist?(yoda_dir_path) && FileUtils.rm_rf(yoda_dir_path)
        end

        private

        def expand_path(relative_path, base_path = project.root_path)
          return nil unless base_path
          File.expand_path(relative_path, base_path)
        end

        # @param dir_path [String]
        def make_dir_at(dir_path)
          dir_path && (File.exist?(dir_path) || FileUtils.mkdir_p(dir_path))
        end
      end
    end
  end
end
