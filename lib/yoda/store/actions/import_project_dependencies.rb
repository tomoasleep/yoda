module Yoda
  module Store
    module Actions
      class ImportProjectDependencies
        # @return [Project]
        attr_reader :project

        # @param errors [Array<BaseError>]
        attr_reader :errors

        # @param project [Project]
        def initialize(project)
          @project = project
          @errors = []
        end

        def run
          libraries_status = project.registry.libraries.status
          library_to_add, library_to_remove = calculate_dependency(libraries_status)

          if !library_to_add.empty? || !library_to_remove.empty?
            Logger.info 'Constructing database for the current project.'
            project.registry.libraries.modify(add: library_to_add, remove: library_to_remove)
          end

          self
        end

        private

        # @param libraries_status [Object::LibrariesStatus]
        def calculate_dependency(libraries_status)
          libraries = Objects::LibrariesStatus.libraies_from_dependency(project.dependency)
          library_to_add = libraries - libraries_status.libraries
          library_to_remove = libraries_status.libraries - libraries
          [library_to_add, library_to_remove]
        end
      end
    end
  end
end
