module Yoda
  module Typing
    class Inferencer
      class LoadResolver
        # @return [Store::Project]
        attr_reader :project

        # @param project [Store::Project]
        def initialize(project)
          @project = project
        end

        # @param path [String]
        # @return [String, nil]
        def resolve(path)
          path_at_project = Services::LoadablePathResolver.new.find_loadable_path(project.project_load_paths, path)
          return path_at_project if path_at_project

          found_library = libraries.find do |gem|
            gem.contain_requirable_file?(path)
          end

          found_library&.find_requirable_file(path)
        end

        def libraries
          [
            # In search priority order
            project.dependency.loadable_gems,
            project.dependency.std,
            project.dependency.core
          ].flatten.map { |lib| lib.with_project_connection(project: project) }
        end
      end
    end
  end
end
