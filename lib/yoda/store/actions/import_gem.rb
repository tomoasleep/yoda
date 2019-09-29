require 'open3'

module Yoda
  module Store
    module Actions
      class ImportGem
        # @return [Project::Dependency::Library]
        attr_reader :dep

        class << self
          # @return [true, false]
          def run(args = {})
            new(args).run
          end
        end

        # @param dep [Project::Dependency::Library]
        def initialize(dep)
          @dep = dep
        end

        # @return [Objects::Patch]
        def run
          create_dependency_doc
          if yardoc_file = yardoc_path
            load_yardoc(yardoc_file, gem_path)
          end
        end

        private

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

        def gem_name
          dep.name
        end

        def gem_version
          dep.version
        end

        # @return [String]
        def gem_path
          dep.full_gem_path
        end
      end
    end
  end
end
