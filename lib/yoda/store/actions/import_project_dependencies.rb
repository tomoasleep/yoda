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
            Logger.trace 'Adding libraries: ' + library_to_add.map(&:name).join(', ')
            Logger.trace 'Removing libraries: ' + library_to_remove.map(&:name).join(', ')
            project.registry.libraries.modify(add: library_to_add, remove: library_to_remove)
          else
            Logger.info 'No library changes to the current project.'
          end

          self
        end

        private

        # @param libraries_status [Object::LibrariesStatus]
        # @return [Array(Array<Object::Library::Core, Objects::Library::Std, Objects::Library::Gem>, Array<Object::Library::Core, Objects::Library::Std, Objects::Library::Gem>)]
        def calculate_dependency(libraries_status)
          libraries = Objects::LibrariesStatus.libraies_from_dependency(project.dependency)
          Logger.trace 'Requested libraries: ' + libraries.map(&:name).join(', ')
          library_to_add = libraries - libraries_status.libraries

          library_to_add_names = library_to_add.map(&:name)
          library_to_reset = (libraries_status.libraries - libraries).select { |library| library_to_add_names.include?(library.name) }

          [library_to_add, library_to_reset]
        end
      end
    end
  end
end
