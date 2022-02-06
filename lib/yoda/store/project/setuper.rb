require "yoda/instrument"
require "ruby-progressbar"

module Yoda
  module Store
    class Project
      class Setuper
        # @return [Project]
        attr_reader :project

        # @return [Hash{ Symbol => ProgressBar }]
        attr_reader :bars

        # @param project [Project]
        def initialize(project)
          @project = project
          @bars = {}
        end

        # @param rebuild [Boolean]
        # @return [Project]
        def run(rebuild: false)
          build_core_index

          if rebuild
            clear
          end

          project.file_finder.make_dir
          build_project_cache

          errors = import_project_dependencies
          project.rbs_environment
          load_project_files
          errors
        end

        def clear
          project.file_finder.clear_dir
        end

        def reset
          run(rebuild: true)
        end

        private

        def load_project_files
          Logger.debug('Loading current project files...')
          Instrument.instance.initialization_progress(phase: :load_project_files, message: 'Loading current project files')
          project.root_path && Actions::ReadProjectFiles.for_project(project).run
        end

        # @return [Array<BaseError>]
        def import_project_dependencies
          Actions::ImportProjectDependencies.new(project).run.errors
        end

        def build_project_cache
          if project.gemfile_lock_path
            Logger.info 'Building index for the current project...'
            Instrument.instance.hear(initialization_progress: method(:on_progress), registry_dump: method(:on_progress)) do
              import_project_dependencies
            end
          else
            Logger.info 'Skipped building project index because Gemfile.lock is not exist for the current dir'
          end
        end

        def build_core_index
          Actions::BuildCoreIndex.run unless Actions::BuildCoreIndex.exists?
        end

        def on_progress(phase: :save_keys, index: nil, length: nil, **params)
          return unless index
          bar = bars[phase] ||= ProgressBar.create(format: "%t: %c/%C |%w>%i| %e ", title: phase.to_s.gsub('_', ' '), starting_at: index, total: length)
          bar.progress = index if index <= bar.total
        end
      end
    end
  end
end
