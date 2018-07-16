require 'bundler'

module Yoda
  module Store
    class Project
      class Builder
        # @return [Registry]
        attr_reader :registry

        # @return [String]
        attr_reader :root_path

        # @return [String]
        attr_reader :gemfile_lock_path

        class << self
          def build(project, progress: false)
            STDERR.puts 'Constructing database for the current project.'
            YARD::Logger.instance(STDERR)
            project.cache.setup
            project.registry.adapter.clear
            Builder.new(project.registry, project.root_path, gemfile_lock_path).run(progress: progress)
            STDERR.puts 'Finished to construct database for the current project.'
          end
        end

        def initialize(registry, root_path, gemfile_lock_path)
          @registry = registry
          @root_path = root_path
          @gemfile_lock_path = gemfile_lock_path
        end

        def run(progress: false)
          Actions::ImportCoreLibrary.new(registry).run
          if File.exist?(gemfile_lock_path)
            Actions::ImportGems.new(registry, gemfile_lock_parser.specs).run
          end
          registry.compress_and_save(progress: progress)
        end

        def gemfile_lock_parser
          Dir.chdir(root_path) do
            Bundler::LockfileParser.new(File.read(gemfile_lock_path))
          end
        end
      end
    end
  end
end
