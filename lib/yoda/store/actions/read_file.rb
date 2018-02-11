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
        def self.run(registry, file)
          self.new(registry, file).run
        end

        # @param registry [Registry]
        # @param file [String]
        def initialize(registry, file)
          @registry = registry
          @file = file
        end

        # @return [void]
        def run
          YARD::Registry.clear
          YARD.parse([file])
          patch = YardImporter.new(file).import(YARD::Registry.all + [YARD::Registry.root]).patch
          registry.add_patch(patch)
        end
      end
    end
  end
end
