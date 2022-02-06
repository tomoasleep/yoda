require 'rbs'

module Yoda
  module Store
    class Project
      # Find registry file for the current project settings.
      class RbsLoader
        # @return [Project]
        attr_reader :project

        # @param project [Project]
        def initialize(project)
          @project = project
        end

        # @return [RBS::Environment]
        def rbs_environment
          @rbs_environment ||= begin
            repository = RBS::Repository.new
            project.config.rbs_repository_paths.each do |repo_path|
              pathname = Pathname(repo_path).expand_path(root_path)
              repository.add(pathname)
            end

            loader = RBS::EnvironmentLoader.new(repository: repository)
            project.config.rbs_signature_paths.each do |sig_path|
              pathname = Pathname(sig_path).expand_path(root_path)
              loader.add(path: pathname)
            end

            project.config.rbs_libraries.each do |library|
              loader.add(library: library)
            end

            RBS::Environment.from_loader(loader).resolve_type_names
          end
        end
      end
    end
  end
end
