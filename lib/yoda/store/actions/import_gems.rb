module Yoda
  module Store
    module Actions
      class ImportGems
        # @return [Registry]
        attr_reader :registry

        # @return [Array<Bundler::Gem::Specification>]
        attr_reader :gem_specs

        def initialize(registry, gem_specs)
          @registry = registry
          @gem_specs = gem_specs
        end

        def run
          create_dependency_docs
          yardoc_files_of_dependencies.map do |yardoc_file|
            if patch = load_yardoc(yardoc_file)
              registry.add_patch(patch)
            end
          end
        end

        private

        def create_dependency_docs
          gem_specs.each do |gem|
            STDERR.puts "Building gem docs for #{gem.name} #{gem.version}"
            begin
              Thread.new do
                YARD::CLI::Gems.run(gem.name, gem.version)
              end.join
              STDERR.puts "Done building gem docs for #{gem.name} #{gem.version}"
            rescue => ex
              STDERR.puts ex
              STDERR.puts ex.backtrace
              STDERR.puts "Failed to build #{gem.name} #{gem.version}"
            end
          end
        end

        def yardoc_files_of_dependencies
          gem_specs.map { |gem| YARD::Registry.yardoc_file_for_gem(gem.name, gem.version) }.compact
        rescue Bundler::BundlerError => ex
          STDERR.puts ex
          STDERR.puts ex.backtrace
          []
        end

        def load_yardoc(yardoc_file)
          begin
            YardImporter.import(yardoc_file)
          rescue => ex
            STDERR.puts ex
            STDERR.puts ex.backtrace
            STDERR.puts "Failed to load #{yardoc_file}"
            nil
          end
        end
      end
    end
  end
end
