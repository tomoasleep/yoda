module Yoda
  module Store
    module Actions
      class ReadProjectFiles
        # @return [Registry]
        attr_reader :registry

        # @return [String]
        attr_reader :root_path

        def initialize(registry, root_path)
          @registry = registry
          @root_path = root_path
        end

        def run
          files = project_files
          progress = Instrument::Progress.new(files.length) do |index:, length:|
            Instrument.instance.initialization_progress(phase: :load_project_files, message: "Loading current project files (#{index} / #{length})", index: index, length: length)
          end

          files.each do |file|
            ReadFile.run(registry, file)
            progress.increment
          end
        end

        private

        # @return [Array<String>]
        def project_files
          Dir.chdir(root_path) { Dir.glob("{lib,app}/**/*.rb\0ext/**/*.c\0.yoda/*.rb").map { |name| File.expand_path(name, root_path) } }
        end
      end
    end
  end
end
