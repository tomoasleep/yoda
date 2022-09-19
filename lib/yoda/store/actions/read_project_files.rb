module Yoda
  module Store
    module Actions
      class ReadProjectFiles
        # @return [Project]
        attr_reader :project

        # @return [Registry]
        attr_reader :registry

        # @param project [Project]
        # @return [ReadProjectFiles]
        def self.for_project(project)
          new(project, project.registry)
        end

        # @param project [Project]
        # @param registry [Project]
        def initialize(project, registry)
          @project = project
          @registry = registry
        end

        def run
          files = project_files
          progress = Instrument::Progress.new(files.length) do |index:, length:|
            Instrument.instance.initialization_progress(phase: :load_project_files, message: "Loading current project files (#{index} / #{length})", index: index, length: length)
          end

          patches = ActionProcessRunner.new.run do
            yardoc_runner = YardocRunner.new(source_dir_path: project.root_path, file_paths: files)
            yardoc_runner.run(import_each: true)
          end
          
          patches.each do |patch|
            registry.local_store.add_file_patch(patch)
            progress.increment
          end
        end

        private

        # @return [Array<String>]
        def project_files
          project.project_source_paths
        end
      end
    end
  end
end
