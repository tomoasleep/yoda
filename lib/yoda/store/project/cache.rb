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
        end

        # @return [true, false]
        def present?
          File.exist?(cache_path)
        end

        # @return [Registry]
        def prepare_registry
          make_cache_dir
          Registry.new(Adapters.default_adapter_class.for(cache_path))
        end

        # @return [String]
        def cache_path
          File.expand_path(cache_name, cache_dir_path)
        end

        private

        # @return [String]
        def cache_name
          @cache_path ||= begin
            digest = Digest::SHA256.new
            digest.file(gemfile_lock_path) if gemfile_lock_path && File.exist?(gemfile_lock_path)
            digest.update(Registry::REGISTRY_VERSION.to_s)
            digest.update(Adapters.default_adapter_class.type.to_s)
            digest.hexdigest
          end
        end

        def make_cache_dir
          File.exist?(cache_dir_path) || FileUtils.mkdir_p(cache_dir_path)
        end
      end
    end
  end
end
