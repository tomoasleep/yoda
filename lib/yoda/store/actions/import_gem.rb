require 'open3'

module Yoda
  module Store
    module Actions
      class ImportGem
        # @return [Project]
        attr_reader :project

        # @return [String]
        attr_reader :gem_name, :gem_version

        class << self
          # @return [true, false]
          def run(args = {})
            new(args).run
          end
        end

        # @param project [Project]
        # @param gem_name [String]
        # @param gem_version [String]
        def initialize(project:, gem_name:, gem_version:)
          @project = project
          @gem_name = gem_name
          @gem_version = gem_version
        end

        # @return [LibraryRegistry, nil]
        def run
          return unless gem_dependency
          create_dependency_doc
          if yardoc_file = yardoc_path
            patch = load_yardoc(yardoc_file, gem_path)
            lib = project.dependency.gem_dependency(name: gem_name, version: gem_version)
            LibraryRegistry.create_from_patch(gem_dependency, patch)
          end
          nil
        end

        private

        # @return [Project::Dependency::Library]
        def gem_dependency
          @gem_dependency ||= project.dependency.gem_dependency(name: gem_name, version: gem_version)
        end

        def create_dependency_doc
          if yardoc_path
            Logger.info "Gem docs for #{gem_name} #{gem_version} already exist"
            return true
          end
          Logger.info "Building gem docs for #{gem_name} #{gem_version}"
          begin
            o, e = Open3.capture2e("yard gems #{gem_name} #{gem_version}")
            Logger.debug o unless o.empty?
            if e.success?
              Logger.info "Done building gem docs for #{gem_name} #{gem_version}"
            else
              Logger.warn "Failed to build #{gem_name} #{gem_version}"
            end
          rescue => ex
            Logger.debug ex
            Logger.debug ex.backtrace
            Logger.warn "Failed to build #{gem_name} #{gem_version}"
          end
        end

        # @param yardoc_file [String]
        # @param gem_source_path [String]
        # @return [Objects::Patch, nil]
        def load_yardoc(yardoc_file, gem_source_path)
          begin
            YardImporter.import(yardoc_file, root_path: gem_source_path)
          rescue => ex
            Logger.debug ex
            Logger.debug ex.backtrace
            Logger.warn "Failed to load #{yardoc_file}"
            nil
          end
        end

        # @return [String, nil]
        def yardoc_path
          YARD::Registry.yardoc_file_for_gem(gem_name, gem_version)
        rescue Bundler::BundlerError => ex
          Logger.debug ex
          Logger.debug ex.backtrace
          nil
        end

        # @return [String]
        def gem_path
          gem_dependency.full_gem_path
        end
      end
    end
  end
end
