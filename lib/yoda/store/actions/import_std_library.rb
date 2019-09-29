module Yoda
  module Store
    module Actions
      class ImportStdLibrary
        # @return [Project::Dependency::Std]
        attr_reader :dep

        class << self
          # @param dep [Project::Dependency::Std]
          # @return [Objects::Patch]
          def run(dep)
            new(dep).run
          end
        end

        # @param dep [Project::Dependency::Std]
        def initialize(dep)
          @dep = dep
        end

        # @return [Objects::Patch]
        def run
          BuildCoreIndex.run unless BuildCoreIndex.exists?
          return false unless File.exist?(dep.doc_path)
          YardImporter.import(dep.doc_path)
        end
      end
    end
  end
end
