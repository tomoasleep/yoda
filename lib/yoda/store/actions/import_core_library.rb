module Yoda
  module Store
    module Actions
      class ImportCoreLibrary
        # @return [Project::Dependency::Core]
        attr_reader :dep

        class << self
          # @param dep [Project::Dependency::Core]
          # @return [Objects::Patch]
          def run(dep)
            new(dep).run
          end
        end

        # @param dep [Project::Dependency::Core]
        def initialize(dep)
          @dep = dep
        end

        # @return [Objects::Patch]
        def run
          BuildCoreIndex.run unless BuildCoreIndex.exists?
          return unless File.exist?(dep.doc_path)
          patch = YardImporter.import(dep.doc_path)
          Transformers::CoreVisibility.transform(patch)
        end
      end
    end
  end
end
