require 'yoda/store/objects/library/path_resolvable'

module Yoda
  module Store
    module Objects
      module Library
        module PathResolvable
          # @abstract
          # @return [Array<String>]
          def require_paths
            fail NotImplementedError
          end

          # @param relative_path [String]
          # @return [Boolean]
          def contain_requirable_file?(relative_path)
            !!find_requirable_file(relative_path)
          end

          # @param relative_path [String]
          # @return [String, nil]
          def find_requirable_file(relative_path)
            Services::LoadablePathResolver.new.find_loadable_path(require_paths, relative_path)
          end
        end
      end
    end
  end
end
