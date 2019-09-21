module Yoda
  module Store
    module Actions
      class ImportCoreLibrary
        # @return [Project]
        attr_reader :project

        class << self
          # @return [LibraryRegistry]
          def run(project)
            new(project).run
          end
        end

        # @param project [Project]
        def initialize(project)
          @project = project
        end

        # @return [LibraryRegistry]
        def run
          return unless File.exist?(project.dependency.core.doc_path)
          patch = YardImporter.import(project.dependency.core.doc_path)
          LibraryRegistry.create_from_patch(project.dependency.core, patch)
        end
      end
    end
  end
end
