require 'open3'

module Yoda
  module Store
    module Actions
      class ImportGem
        # @return [Objects::Library::Gem::Connected]
        attr_reader :dep

        class << self
          # @return [true, false]
          def run(args = {})
            new(args).run
          end
        end

        # @param dep [Objects::Library::Gem::Connected]
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
          if dep.managed_by_rubygems? && readable?(yardoc_path)
            Logger.info "Gem docs for #{gem_name} #{gem_version} already exist"
            return
          end

          if yardoc_path
            Logger.info "Building gem docs for #{gem_name} #{gem_version}"
            yard_doc_command
          else
            Logger.info "Cannot build gem docs for #{gem_name} #{gem_version}"
          end
        end

        def yard_doc_command
          begin
            o, e = Dir.chdir(gem_path) do
              Open3.capture2e("yard --no-stats --no-output -b #{yardoc_path} -c")
            end
            Logger.debug o unless o.empty?
            if e.success?
              Logger.info "Done building gem docs for #{gem_name} #{gem_version}"
            else
              Logger.warn "Failed to build #{gem_name} #{gem_version}"
              fail ImportError, "Failed to build #{gem_name} #{gem_version}"
            end
          rescue => ex
            Logger.debug ex
            Logger.debug ex.backtrace
            Logger.warn "Failed to build #{gem_name} #{gem_version}"
            fail ImportError, "Failed to build #{gem_name} #{gem_version}"
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
          return nil unless readable?(gem_path)

          if dep.managed_by_rubygems?
            candidate = File.expand_path('.yardoc', dep.doc_dir)
            if writable?(candidate)
              candidate
            else
              dep.project.library_local_yardoc_path(name: gem_name, version: gem_version)
            end
          else
            candidate = File.expand_path('.yardoc', gem_path)
            if writable?(candidate)
              candidate
            else
              dep.project.library_local_yardoc_path(name: gem_name, version: gem_version)
            end
          end
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

        # @param path [String]
        # @return [Boolean]
        def writable?(path)
          return true if File.writable?(path)
          return true if !File.directory?(path) && File.writable?(File.dirname(path))
          false
        end

        # @param path [String]
        # @return [Boolean]
        def readable?(path)
          return false unless path
          return false unless File.readable?(path)
          true
        end
      end
    end
  end
end
