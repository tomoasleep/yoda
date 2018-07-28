require 'open3'

module Yoda
  module Store
    module Actions
      class ImportGem
        # @return [Registry]
        attr_reader :registry

        # @return [String]
        attr_reader :gem_name, :gem_version

        class << self
          # @return [true, false]
          def run(args = {})
            new(args).run
          end
        end

        # @param registry [Registry]
        # @param gem_name [String]
        # @param gem_version [String]
        def initialize(registry:, gem_name:, gem_version:)
          @registry = registry
          @gem_name = gem_name
          @gem_version = gem_version
        end

        # @return [true, false]
        def run
          create_dependency_doc
          if yardoc_file = yardoc_path
            if patch = load_yardoc(yardoc_file, gem_path)
              registry.add_patch(patch)
              return true
            end
          end
          false
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

        # @return [String, nil]
        def gem_path
          @gem_path ||= begin
            if spec = Gem.source_index.find_name(gem_name).first
              spec.full_gem_path
            end
          end
        end
      end
    end
  end
end
