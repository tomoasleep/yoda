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
          project_status = registry.project_status || Objects::ProjectStatus.initial_build(dependencies: project.dependencies)
          bundle_status = project_status.bundle

          unless bundle_status.all_present?
            Logger.info 'Constructing database for the current project.'

            # Try to import missing gems and core libraries.
            Instrument.instance.initialization_progress(phase: :load_core, message: 'Loading core index')

            bundle_status = import_core(bundle_status) unless bundle_status.std_status.core_present?
            bundle_status = import_std(bundle_status) unless bundle_status.std_status.std_present?
            bundle_status = import_libraries(bundle_status)

            Instrument.instance.initialization_progress(phase: :save, message: 'Saving registry')
            registry.compress_and_save
            registry.save_project_status(project_status.derive(bundle: bundle_status))
          end
        end

        private

        # @return [Registry]
        def registry
          project.registry
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
