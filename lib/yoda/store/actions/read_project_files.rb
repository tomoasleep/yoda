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
          project_files.each { |file| ReadFile.run(registry, file) }
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
