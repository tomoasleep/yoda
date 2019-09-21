module Yoda
  module Store
    module Actions
      class ImportStdLibrary
        # @return [Project]
        attr_reader :project

        class << self
          # @return [LibraryRegistry]
          def run(project)
            new(project).run
          end
        end

        # @param project [Project]
        def initialize(Project)
          @project = project
        end

        # @return [LibraryRegistry]
        def run
          return false unless File.exist?(project.dependency.std.doc_path)
          patch = YardImporter.import(project.dependency.std.doc_path)
          LibraryRegistry.create_from_patch(project.dependency.std, patch)
        end
      end
    end
  end
end
