module Yoda
  module Store
    module Objects
      module Library
        module WithRegistry
          # @return [Boolean]
          def registry_exists?
            File.exists?(registry_path)
          end

          # Return the path of registry for the library.
          # @abstract
          # @return [String]
          def registry_path
            fail NotImplementedError
          end

          # @return [Registry::LibraryRegistry]
          def registry
            @registry ||= begin
              Registry::LibraryRegistry.for_library(self)
            end
          end
        end
      end
    end
  end
end
