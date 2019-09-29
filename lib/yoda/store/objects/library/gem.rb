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
              spec.__materialize__
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

          private

          def global_registry_dir_path
            registry_path = File.join(doc_dir, '.yoda')
            if File.writable?(doc_dir)
              registry_path
            end
          end
        end
      end
    end
  end
end
