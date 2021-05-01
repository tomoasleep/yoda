module Yoda
  module Store
    module Objects
      module Library
        class Gem
          include WithRegistry
          include Serializable
          
          # @return [String]
          attr_reader :name, :version, :source_path, :full_gem_path, :doc_dir

          class << self
            # @param spec [Bundler::LazySpecification]
            def from_gem_spec(spec)
              fail "#{spec} is not installed" unless spec.respond_to?(:full_gem_path)
              new(
                name: spec.name,
                version: spec.version.version,
                source_path: spec.source.respond_to?(:path) ? spec.source.path : nil,
                full_gem_path: spec.full_gem_path,
                doc_dir: spec.doc_dir,
              )
            end
          end

          # @param spec [Bundler::LazySpecification]
          def initialize(name:, version:, source_path:, full_gem_path:, doc_dir:)
            @name = name
            @version = version
            @source_path = source_path
            @full_gem_path = full_gem_path
            @doc_dir = doc_dir
          end

          def id
            "#{name}:#{version}"
          end

          def local?
            source_path
          end

          def create_patch
            Actions::ImportGem.run(self)
          end

          def to_h
            {
              name: name,
              version: version,
              source_path: source_path,
              full_gem_path: full_gem_path,
              doc_dir: doc_dir,
            }
          end

          # @note Implementation for {WithRegistry#registry_path}
          def registry_path
            VersionStore.for_current_version.registry_path_for_gem(name: name, version: version)
          end
        end
      end
    end
  end
end
