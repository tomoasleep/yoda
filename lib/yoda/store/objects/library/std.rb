module Yoda
  module Store
    module Objects
      module Library
        class Std
          include WithRegistry
          include Serializable

          # @return [String]
          attr_reader :version

          # @return [Core]
          def self.current_version
            new
          end

          # @param version [String]
          def initialize(version: RUBY_VERSION)
            @version = version
          end

          def to_h
            { version: version }
          end

          def id
            name
          end

          def name
            'std'
          end

          def version
            RUBY_VERSION
          end

          def doc_path
            VersionStore.for_current_version.stdlib_yardoc_path
          end

          def create_patch
            Actions::ImportStdLibrary.run(self)
          end

          # @note Implementation for {WithRegistry#registry_path}
          def registry_path
            VersionStore.for_current_version.registry_path_for_stdlib
          end
        end
      end
    end
  end
end
