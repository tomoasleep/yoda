require 'open3'
require 'yoda/store/actions/action_process_runner'

module Yoda
  module Store
    module Actions
      class ImportGem
        include ActionProcessRunner::Mixin

        # @return [Objects::Library::Gem::Connected]
        attr_reader :dep

        class << self
          # @param (see #initialize)
          # @return (see #run)
          def run(dep)
            new(dep).run
          end

          # @param (see #initialize)
          # @return (see #run)
          def run_process(dep)
            new(dep).run_process
          end
        end

        # @param dep [Objects::Library::Gem::Connected]
        def initialize(dep)
          @dep = dep
        end

        # @return [Array<Objects::Patch>]
        def run
          [
            *(run_yardoc || []),
            *(run_rbs || []),
          ]
        end

        private

        # @return [Array<Objects::Patch>, nil]
        def run_rbs
          patch = ImportRbs.for_gem_library(dep)&.run
          patch ? [patch] : []
        rescue => ex
          Logger.debug ex
          Logger.debug ex.backtrace
          Logger.warn "Failed to build #{gem_name} #{gem_version}"
          fail ImportError, "Failed to build #{gem_name} #{gem_version}"
        end

        # @return [Array<Objects::Patch>, nil]
        def run_yardoc
          begin
            yardoc_runner.run
          rescue => ex
            Logger.debug ex
            Logger.debug ex.backtrace
            Logger.warn "Failed to build #{gem_name} #{gem_version}"
            fail ImportError, "Failed to build #{gem_name} #{gem_version}"
          end
        end

        # @return [YardocRunner]
        def yardoc_runner
          @yardoc_runner ||= YardocRunner.new(source_dir_path: gem_path, database_path: yardoc_path, id: YardImporter.patch_id_for_file(yardoc_path))
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
