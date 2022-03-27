require 'yoda/store/objects/library/path_resolvable'

module Yoda
  module Store
    module Objects
      module Library
        class Gem
          include Serializable
          include PathResolvable

          # @return [String]
          attr_reader :name, :version, :source_path, :full_gem_path, :doc_dir

          # @return [Array<String>]
          attr_reader :require_paths

          # @return [Symbol, nil]
          attr_reader :source_type

          class << self
            # @param spec [Bundler::LazySpecification, Gem::Specification]
            def from_gem_spec(spec)
              if spec.respond_to?(:full_gem_path)
                # Installed
                new(
                  name: spec.name,
                  version: spec.version.version,
                  source_path: spec.source.respond_to?(:path) ? spec.source.path : nil,
                  require_paths: spec.full_require_paths,
                  full_gem_path: spec.full_gem_path,
                  doc_dir: spec.doc_dir,
                  source_type: source_type_of(spec.source),
                )
              else
                # Not installed
                new(
                  name: spec.name,
                  version: spec.version.version,
                  source_path: nil,
                  require_paths: [],
                  full_gem_path: nil,
                  doc_dir: nil,
                  source_type: nil,
                )
              end
            end

            # @param source [Bundler::Source, nil]
            # @return [Symbol, nil]
            def source_type_of(source)
              return nil unless source

              case source
              when Bundler::Source::Git
                :git
              when Bundler::Source::Gemspec
                :gemspec
              when Bundler::Source::Rubygems
                :rubygems
              when Bundler::Source::Path
                :path
              else
                nil
              end
            end
          end

          def initialize(name:, version:, source_path:, full_gem_path:, require_paths:, doc_dir:, source_type:)
            @name = name
            @version = version
            @source_path = source_path
            @full_gem_path = full_gem_path
            @require_paths = require_paths
            @doc_dir = doc_dir
            @source_type = source_type&.to_sym
          end

          def id
            "#{name}:#{version}"
          end

          def local?
            source_path
          end

          def to_h
            {
              name: name,
              version: version,
              source_path: source_path,
              full_gem_path: full_gem_path,
              require_paths: require_paths,
              doc_dir: doc_dir,
              source_type: source_type,
            }
          end

          # @return [Boolean]
          def installed?
            full_gem_path && File.exists?(full_gem_path)
          end

          def managed_by_rubygems?
            source_type == :rubygems
          end

          # @return [Connected]
          def with_project_connection(**kwargs)
            self.class.const_get(:Connected).new(self, **kwargs)
          end

          class Connected
            extend ConnectedDelegation
            include WithRegistry

            delegate_to_object :name, :version, :source_path, :full_gem_path, :doc_dir, :source_type, :require_paths
            delegate_to_object :id, :local?, :to_h, :installed?, :managed_by_rubygems?, :with_project_connection
            delegate_to_object :hash, :eql?, :==, :to_json, :derive
            delegate_to_object :contain_requirable_file?, :find_requirable_file

            # @return [Gem]
            attr_reader :object

            # @return [Project]
            attr_reader :project

            # @param object [Gem]
            # @param project [Project]
            def initialize(object, project:)
              @object = object
              @project = project
            end

            # @note Implementation for {WithRegistry#registry_path}
            def registry_path
              if managed_by_rubygems?
                project.library_registry_path(name: name, version: version)
              else
                # Do not persist not gems.
                nil
              end
            end

            def create_patch
              Actions::ImportGem.run(self)
            end
          end
        end
      end
    end
  end
end
