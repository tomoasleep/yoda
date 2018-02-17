module Yoda
  module Store
    module Actions
      class ImportCoreLibrary
        # @return [Registry]
        attr_reader :registry

        def initialize(registry)
          @registry = registry
        end

        def run
          load_core_patches.each do |patch|
            registry.add_patch(patch)
          end
        end

        private

        def load_core_patches
          core_doc_files.map { |yardoc_file| YardImporter.import(yardoc_file) }
        end

        def core_doc_files
          %W(.yoda/sources/ruby-#{RUBY_VERSION}/.yardoc .yoda/sources/ruby-#{RUBY_VERSION}/.yardoc-stdlib).map { |path| File.expand_path(path, '~') }.select { |path| File.exist?(path) }
        end
      end
    end
  end
end
