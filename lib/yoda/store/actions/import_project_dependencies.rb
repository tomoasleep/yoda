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
          project_status = project.registry.project_status
          library_to_add, library_to_remove = calculate_dependency(project_status)

          if !library_to_add.empty? || !library_to_remove.empty?
            Logger.info 'Constructing database for the current project.'
            project.registry.modify_libraries(add: library_to_add, remove: library_to_remove)
          end

          self
        end

        private

        # @param project_status [Object::ProjectStatus]
        def calculate_dependency(project_status)
          libraries = Objects::ProjectStatus.libraies_from_dependency(project.dependency)
          library_to_add = libraries - project_status.libraries
          library_to_remove = project_status.libraries - libraries
          [library_to_add, library_to_remove]
        end
      end
    end
  end
end
