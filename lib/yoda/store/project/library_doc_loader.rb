module Yoda
  module Store
    class Project
      class LibraryDocLoader
        # @return [Registry]
        attr_reader :registry

        # @param gem_specs [Array<Objects::ProjectStatus::GemStatus, Bundler::LazySpecification>]
        attr_reader :gem_specs

        # @param errors [Array<BaseError>]
        attr_reader :errors

        class << self
          # @param project [Project]
          # @return [LibraryDocLoader]
          def build_for(project)
            new(registry: project.registry, gem_specs: gem_specs(project))
          end

          private

          # @return [Bundler::LockfileParser, nil]
          def parse_gemfile_lock(root_path, gemfile_lock_path)
            return if !gemfile_lock_path || !File.exists?(gemfile_lock_path)
            Dir.chdir(root_path) do
              Bundler::LockfileParser.new(File.read(gemfile_lock_path))
            end
          end

          def gem_specs(project)
            lockfile_parser = parse_gemfile_lock(project.root_path, Cache.gemfile_lock_path(project.root_path))
            (lockfile_parser&.specs || []).reject do |spec|
              spec.source.is_a?(Bundler::Source::Path) && (File.expand_path(spec.source.path) == File.expand_path(project.root_path))
            end
          end
        end

        # @param registry [Registry]
        # @param gem_specs [Array<Objects::ProjectStatus::GemStatus, Bundler::LazySpecification>]
        def initialize(registry:, gem_specs:)
          @registry = registry
          @gem_specs = gem_specs
          @errors = []
        end

        def run
          project_status = registry.project_status || Objects::ProjectStatus.initial_build(specs: gem_specs)
          new_bundle_status = update_bundle(project_status.bundle)
          registry.save_project_status(project_status.derive(bundle: new_bundle_status))
        end

        private

        # @param bundle_status [Objects::ProjectStatus::BundleStatus]
        # @return [Objects::ProjectStatus::BundleStatus]
        def update_bundle(bundle_status)
          unless bundle_status.all_present?
            Logger.info 'Constructing database for the current project.'
            bundle_status = import_deps(bundle_status)
            registry.compress_and_save
          end
          bundle_status
        end

        # Try to import missing gems and core libraries.
        # @param bundle_status [Objects::ProjectStatus::BundleStatus]
        # @return [Objects::ProjectStatus::BundleStatus]
        def import_deps(bundle_status)
          Instrument.instance.initialization_progress(phase: :load_core, message: 'Loading core index')
          bundle_status = import_core(bundle_status) unless bundle_status.std_status.core_present?
          bundle_status = import_std(bundle_status) unless bundle_status.std_status.std_present?
          import_gems(bundle_status)
        end

        # @param bundle_status [Objects::ProjectStatus::BundleStatus]
        # @return [Objects::ProjectStatus::BundleStatus]
        def import_core(bundle_status)
          result = Actions::ImportCoreLibrary.run(registry)
          errors.push(CoreImportError.new('core')) unless result
          bundle_status.derive(std_status: bundle_status.std_status.derive(core_present: !!result))
        end

        # @param bundle_status [Objects::ProjectStatus::BundleStatus]
        # @return [Objects::ProjectStatus::BundleStatus]
        def import_std(bundle_status)
          result = Actions::ImportStdLibrary.run(registry)
          errors.push(CoreImportError.new('std')) unless result
          bundle_status.derive(std_status: bundle_status.std_status.derive(std_present: !!result))
        end

        # @param bundle_status [Objects::ProjectStatus::BundleStatus]
        # @return [Objects::ProjectStatus::BundleStatus]
        def import_gems(bundle_status)
          present_gem_statuses, absent_gem_statuses = bundle_status.gem_statuses.partition { |gem_status| gem_status.present? }

          progress = Instrument::Progress.new(absent_gem_statuses.length) do |index:, length:|
            Instrument.instance.initialization_progress(phase: :load_gems, message: "Loading gems (#{index} / #{length})", index: index, length: length)
          end

          new_gem_statuses = absent_gem_statuses.map do |gem_status|
            result = Actions::ImportGem.run(registry: registry, gem_name: gem_status.name, gem_version: gem_status.version)
            progress.increment
            errors.push(GemImportError.new(name: gem_status.name, version: gem_status.version)) unless result
            gem_status.derive(present: result)
          end

          bundle_status.derive(gem_statuses: present_gem_statuses + new_gem_statuses)
        end
      end
    end
  end
end
