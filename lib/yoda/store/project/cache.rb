require 'fileutils'
require 'bundler'
require 'tmpdir'
require 'digest'

module Yoda
  module Store
    class Project
      class Cache
        # @return [Project]
        attr_reader :project

        def initialize(project)
          @project = project
        end

        # @return [true, false]
        def present?
          File.exist?(cache_path)
        end

        def setup
          make_cache_dir
          register_adapter
        end

        private

        def register_adapter
          return if project.registry.adapter
          project.registry.adapter = Adapters.default_adapter_class.for(cache_path)
        end

        def make_cache_dir
          File.exist?(cache_dir) || FileUtils.mkdir_p(cache_dir)
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

        def gemfile_lock_path
          File.absolute_path('Gemfile.lock', project.root_path)
        end
      end
    end
  end
end
