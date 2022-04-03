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
        # @param scheduler [Server::Scheduler, nil]
        def run(rebuild: false, scheduler: nil)
          build_core_index

          if rebuild
            clear
          end
          project.file_finder.make_dir

          Logger.info 'Building index for the current project...'

          project.dependency.calculate
          project.registry.reset_view

          project.rbs_environment

          execute(scheduler) do
            dependency_importer.run
            load_project_files
          end
        end

        def clear
          project.file_finder.clear_dir
        end

        def reset
          run(rebuild: true)
        end

        private

        # @param scheduler [Server::Scheduler, nil]
        def execute(scheduler = nil, &block)
          if scheduler
            scheduler.async(id: "setup", &block)
          else
            yield
          end
        end

        def build_core_index
          unless Store::Actions::BuildCoreIndex.exists?
            Instrument.instance.initialization_progress(phase: :core, message: 'Downloading and building core index')
            Store::Actions::BuildCoreIndex.run
          end
        end

        def load_project_files
          Logger.debug('Loading current project files...')
          Instrument.instance.initialization_progress(phase: :load_project_files, message: 'Loading current project files')
          project.root_path && Actions::ReadProjectFiles.for_project(project).run
        end

        # @return [Actions::ImportProjectDependencies]
        def dependency_importer
          Actions::ImportProjectDependencies.new(project)
        end
      end
    end
  end
end
