require 'open3'

module Yoda
  module Store
    module Actions
      class ImportGems
        # @return [Registry]
        attr_reader :registry

        # @return [Array<Bundler::LazySpecification>]
        attr_reader :gem_specs

        # @param registry [Registry]
        # @param gem_specs [Array<Bundler::LazySpecification>]
        def initialize(registry, gem_specs)
          @registry = registry
          @gem_specs = gem_specs
        end

        # @return [void]
        def run
          create_dependency_docs
          gem_specs.map do |gem|
            if yardoc_file = yardoc_file_for_gem(gem)
              if patch = load_yardoc(yardoc_file, gem_path_for(gem))
                registry.add_patch(patch)
              end
            end
          end
        end

        private

        def create_dependency_docs
          gem_specs.each do |gem|
            if yardoc_file_for_gem(gem)
              STDERR.puts "Gem docs for #{gem.name} #{gem.version} already exist"
              next
            end
            STDERR.puts "Building gem docs for #{gem.name} #{gem.version}"
            begin
              o, e = Open3.capture2e("yard gems #{gem.name} #{gem.version}")
              STDERR.puts o unless o.empty?
              if e.success?
                STDERR.puts "Done building gem docs for #{gem.name} #{gem.version}"
              else
                STDERR.puts "Failed to build #{gem.name} #{gem.version}"
              end
            rescue => ex
              STDERR.puts ex
              STDERR.puts ex.backtrace
              STDERR.puts "Failed to build #{gem.name} #{gem.version}"
            end
          end
        end

        # @param gem [Bundler::LazySpecification]
        # @return [String, nil]
        def yardoc_file_for_gem(gem)
          YARD::Registry.yardoc_file_for_gem(gem.name, gem.version)
        rescue Bundler::BundlerError => ex
          STDERR.puts ex
          STDERR.puts ex.backtrace
          nil
        end

        # @param yardoc_file [String]
        # @param gem_source_path [String]
        # @return [Objects::Patch, nil]
        def load_yardoc(yardoc_file, gem_source_path)
          begin
            YardImporter.import(yardoc_file, root_path: gem_source_path)
          rescue => ex
            STDERR.puts ex
            STDERR.puts ex.backtrace
            STDERR.puts "Failed to load #{yardoc_file}"
            nil
          end
        end

        # @param gem [Bundler::LazySpecification]
        # @return [String, nil]
        def gem_path_for(gem)
          if spec = Gem.source_index.find_name(gem.name).first
            spec.full_gem_path
          end
        end
      end
    end
  end
end
