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

          Logger.info 'Constructing database for the current project.' if !library_to_add.empty? || !library_to_remove.empty?

          # registries_to_remove = library_to_remove.map do |library|
          #   case library
          #   when Objects::ProjectStatus::CoreStatus
          #     LibraryRegistry.for_library(project.dependency.core)
          #   when Objects::ProjectStatus::StdStatus
          #     LibraryRegistry.for_library(project.dependency.std)
          #   when Objects::ProjectStatus::GemStatus
          #     result = Actions::ImportGem.run(registry: registry, gem_name: gem_status.name, gem_version: gem_status.version)
          #   when Objects::ProjectStatus::LocalLibraryStatus
          #     result = Actions::ImportLocalLibrary.run(registry: registry, path: lib_status.path)
          #   end
          # end

          unless library_to_add.empty?
            library_to_add.each do |library|
              case library
              when Objects::ProjectStatus::CoreStatus
                bundle_status = import_core(bundle_status)
              when Objects::ProjectStatus::StdStatus
                bundle_status = import_std(bundle_status)
              when Objects::ProjectStatus::GemStatus
                result = Actions::ImportGem.run(registry: registry, gem_name: gem_status.name, gem_version: gem_status.version)
              when Objects::ProjectStatus::LocalLibraryStatus
                result = Actions::ImportLocalLibrary.run(registry: registry, path: lib_status.path)
              end
            end
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

        # @param bundle_status [Objects::ProjectStatus::BundleStatus]
        # @return [Objects::ProjectStatus::BundleStatus]
        def import_core(bundle_status)
          unless result = ImportCoreLibrary.run(registry)
            errors.push(CoreImportError.new('core'))
          end
          bundle_status.derive(std_status: bundle_status.std_status.derive(core_present: !!result))
        end

        # @param bundle_status [Objects::ProjectStatus::BundleStatus]
        # @param project [Project]
        def self.for_project(project)
          path = File.expand_path(project.registry_name, project.cache.cache_dir_path)
          new(adapter: Adapters.for(path))
        end
        # @return [Objects::ProjectStatus::BundleStatus]
        def import_std(bundle_status)
          unless result = ImportStdLibrary.run(registry)
            errors.push(CoreImportError.new('std'))
          end
          bundle_status.derive(std_status: bundle_status.std_status.derive(std_present: !!result))
        end

        # @param bundle_status [Objects::ProjectStatus::BundleStatus]
        # @return [Objects::ProjectStatus::BundleStatus]
        def import_libraries(bundle_status)
          present_gem_statuses, absent_gem_statuses = bundle_status.gem_statuses.partition(&:present?)
          present_lib_statuses, absent_lib_statuses = bundle_status.local_library_statuses.partition(&:present?)

          progress = Instrument::Progress.new(absent_gem_statuses.length + absent_lib_statuses.length) do |index:, length:|
            Instrument.instance.initialization_progress(phase: :load_gems, message: "Loading gems (#{index} / #{length})", index: index, length: length)
          end

          new_gem_statuses = absent_gem_statuses.map do |gem_status|
            result = Actions::ImportGem.run(registry: registry, gem_name: gem_status.name, gem_version: gem_status.version)
            progress.increment
            errors.push(GemImportError.new(name: gem_status.name, version: gem_status.version)) unless result
            gem_status.derive(present: result)
          end

          new_lib_statuses = absent_lib_statuses.map do |lib_status|
            result = Actions::ImportLocalLibrary.run(registry: registry, path: lib_status.path)
            progress.increment
            errors.push(GemImportError.new(name: lib_status.name, version: lib_status.version)) unless result
            lib_status.derive(present: result)
          end

          bundle_status.derive(
            gem_statuses: present_gem_statuses + new_gem_statuses,
            local_library_statuses: present_lib_statuses + new_lib_statuses,
          )
        end
      end
    end
  end
end
