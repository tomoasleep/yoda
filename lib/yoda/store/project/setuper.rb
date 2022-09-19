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
        # @param controller [Server::ServerController, nil]
        def run(rebuild: false, controller: nil)
          if rebuild
            clear
          end
          project.file_finder.make_dir

          Logger.info 'Building index for the current project...'

          project.dependency.calculate
          project.registry.reset_view

          project.rbs_environment

          execute(controller) do
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

        # @param controller [Server::ServerController, nil]
        def execute(controller = nil, &block)
          if controller
            controller.in_new_workdone_progress(title: "setup") do |reporter|
              if reporter
                Server::InitializationProgressReporter.wrap(reporter, &block)
              else
                yield
              end
            end
          else
            yield
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
