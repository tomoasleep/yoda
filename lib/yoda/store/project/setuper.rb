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
        # @return [Array<BaseError>]
        def run(rebuild: false)
          build_core_index

          if rebuild
            clear
          end
          project.file_finder.make_dir

          Logger.info 'Building index for the current project...'
          dependency_importer.run
          project.rbs_environment
          load_project_files

          dependency_importer.errors
        end

        def clear
          project.file_finder.clear_dir
        end

        def reset
          run(rebuild: true)
        end

        private

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
