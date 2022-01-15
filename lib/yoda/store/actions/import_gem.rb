require 'open3'

module Yoda
  module Store
    module Actions
      class ImportGem
        # @return [Objects::Library::Gem]
        attr_reader :dep

        class << self
          # @return [true, false]
          def run(args = {})
            new(args).run
          end
        end

        # @param dep [Objects::Library::Gem]
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
          if dep.managed_by_rubygems?
            if yardoc_path
              Logger.info "Gem docs for #{gem_name} #{gem_version} already exist"
              return true
            end
            Logger.info "Building gem docs for #{gem_name} #{gem_version}"
            yard_gem_command
          elsif yardoc_local_path
            Logger.info "Building gem docs for #{gem_name} #{gem_version}"
            yard_local_doc_command
          else
            Logger.info "Cannot build gem docs for #{gem_name} #{gem_version}"
          end
        end

        def yard_local_doc_command
          begin
            o, e = Dir.chdir(gem_path) do
              Open3.capture2e("yard --no-stats -no-output -c")
            end
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

        def yard_gem_command
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

        def yardoc_path
          if dep.managed_by_rubygems?
            yardoc_gem_path
          else
            yardoc_local_path
          end
        end

        # @return [String, nil]
        def yardoc_local_path
          return nil unless gem_path && File.exist?(gem_path)

          candidate = File.expand_path('.yardoc', gem_path)
          if File.writable?(candidate) || (!File.directory?(candidate) && File.writable?(gem_path))
            candidate
          end
        end

        # @return [String, nil]
        def yardoc_gem_path
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
