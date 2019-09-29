module Yoda
  module Store
    module Objects
      module Library
        module WithRegistry
          def registry_path
            @registry_path ||= File.join(registry_dir_path, registry_name)
          end

          def registry_dir_path
            @registry_dir_path ||= global_registry_dir_path || local_registry_dir_path
          end

          def registry_exists?
            File.exists?(registry_path)
          end

          def registry
            @registry ||= begin
              if registry_exists?
                Registry::LibraryRegistry.for_library(self)
              else
                patch = create_patch
                patch && Registry::LibraryRegistry.create_from_patch(self, patch)
              end
            end
          end

          private

          def registry_name
            @registry_name ||= Registry.registry_name
          end

          def global_registry_dir_path
            nil
          end

          def local_registry_dir_path
            File.join(Project::Dependency::LOCAL_REGISTRY_ROOT, name, version)
          end
        end
      end
    end
  end
end
