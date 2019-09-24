module Yoda
  module Store
    module Actions
      class ReadFile
        # @return [Registry]
        attr_reader :registry

        # @return [String]
        attr_reader :file

        # @param registry [Registry]
        # @param file [String]
        # @return [void]
        def self.run(registry, file, root_path: nil)
          self.new(registry, file, root_path: root_path).run
        end

        # @param registry [Registry]
        # @param file [String]
        def initialize(registry, file, root_path: nil)
          @registry = registry
          @file = file
          @root_path = root_path
        end

        # @return [void]
        def run
          YARD::Registry.clear
          YARD.parse([file])
          patch = YardImporter.new(file).import(YARD::Registry.all + [YARD::Registry.root]).patch
          registry.add_file_patch(patch)
        end
      end
    end
  end
end
