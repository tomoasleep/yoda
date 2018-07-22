module Yoda
  module Store
    module Actions
      class ImportStdLibrary
        # @return [Registry]
        attr_reader :registry

        class << self
          # @return [true, false]
          def run(registry)
            new(registry).run
          end
        end

        def initialize(registry)
          @registry = registry
        end

        # @return [true, false]
        def run
          return false unless File.exist?(doc_path)
          patch = YardImporter.import(doc_path)
          registry.add_patch(patch)
          true
        end

        private

        def doc_path
          File.expand_path("~/.yoda/sources/ruby-#{RUBY_VERSION}/.yardoc-stdlib")
        end
      end
    end
  end
end
