module Yoda
  module Cli
    class AnalyzeDeps
      # @param root_path [String]
      def self.run(root_path)
        require 'json'
        require 'bundler'

        builder = Builder.new(root_path)
        puts JSON.dump(builder)
      end

      class Builder
        # @return [String]
        attr_reader :root_path

        # @param root_path [String]
        def initialize(root_path)
          @root_path = File.expand_path(root_path)
        end

        # @return [Array<Yoda::Store::Objects::Library::Gem>]
        def gems
          @gems ||= dependency_specs.map { |spec| Yoda::Store::Objects::Library::Gem.from_gem_spec(spec) }
        end

        def to_h
          {
            path: root_path,
            dependencies: gems.map(&:to_h),
            autoload_dependency_ids: autoload_gem_ids,
          }
        end

        def to_json(*)
          to_h.to_json
        end

        private

        # @return [Array<Bundler::StubSpecification>]
        def dependency_specs
          @dependency_specs ||= begin
            (gem_specs || [])
              .reject { |spec| self_spec?(spec) || metadata?(spec) }
          end
        end

        # @return [Array<String>]
        def autoload_gem_ids
          if has_gemfile?
            gems.map(&:id)
          else
            []
          end
        end

        # @return [Array<Bundler::LazySpecification, Gem::Specification>, nil]
        def gem_specs
          @gem_specs ||= begin
            with_project_env do
              if has_gemfile?
                # Resolve dependencies of uninstalled gems and ensure remote sources are available.
                Bundler.definition.resolve_remotely!
                spec_set = Bundler.definition.resolve

                if Gem::Version.new(Bundler::VERSION) >= Gem::Version.new('2.2.25')
                  deps = Bundler.definition.requested_dependencies
                  spec_set.materialize(deps).to_a
                else
                  # For backward compatibility (Ref: https://github.com/rubygems/rubygems/pull/4788)
                  deps = Bundler.definition.send(:requested_dependencies)
                  missing = []
                  materialized = spec_set.materialize(deps, missing)

                  materialized.to_a + missing
                end
              else
                [] # Gem::Specification.latest_specs(true)
              end
            end
          end
        end

        # @return [Boolean]
        def has_gemfile?
          File.exist?(File.expand_path("Gemfile", root_path))
        end

        # @param [Gem::Specification]
        def metadata?(spec)
          spec.source.is_a?(Bundler::Source::Metadata)
        end

        # @param [Gem::Specification]
        def self_spec?(spec)
          spec.source.is_a?(Bundler::Source::Path) && (File.expand_path(spec.source.path) == File.expand_path(root_path))
        end

        def with_project_env
          Dir.chdir(root_path) do
            with_unbundled_env do
              # Suppress bundler outputs to stdout.
              Bundler.ui = Bundler::UI::Silent.new
              Bundler.reset!

              yield
            end
          end
        end

        def with_unbundled_env(&block)
          if Bundler.respond_to?(:with_unbundled_env)
            Bundler.with_unbundled_env(&block)
          else
            # For backward compatibility (This method is introduced at bundler 2.1.0: https://github.com/rubygems/bundler/pull/6843)
            Bundler.with_clean_env(&block)
          end
        end
      end
    end
  end
end
