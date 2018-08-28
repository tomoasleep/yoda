module Yoda
  module Store
    module Actions
      class ImportCoreLibrary
        # @return [Registry]
        attr_reader :registry

        class << self
          # @return [true, false]
          def run(registry)
            new(registry).run
          end
        end

        # @param registry [Registry]
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
          File.expand_path("~/.yoda/sources/ruby-#{RUBY_VERSION}/.yardoc")
        end
      end
    end
  end
end
