module Yoda
  module Store
    module Actions
      class ImportLocalLibrary
        # @return [Registry]
        attr_reader :registry

        # @return [String]
        attr_reader :path

        class << self
          # @return [true, false]
          def run(args = {})
            new(args).run
          end
        end

        # @param registry [Registry]
        # @param path [String]
        def initialize(registry:, path:)
          @registry = registry
          @path = path
        end

        # @return [true, false]
        def run
          if File.exist?(doc_path)
            Logger.debug "Yardoc are present at #{doc_path}"
          else
            build_yardoc || (return false)
          end
          patch = YardImporter.import(doc_path)
          registry.add_patch(patch)
          true
        end

        private

        def doc_path
          File.expand_path(".yardoc", path)
        end

        def build_yardoc
          Logger.info "Building yardoc at #{path}"
          Dir.chdir(path) do
            exec_yardoc("yard doc -n .") || (Logger.warn("Failed to build yardoc at #{path}"); return false)
          end
          Logger.info "Success to build yardoc at #{path}"
          true
        end

        def exec_yardoc(cmdline)
          o, e = Open3.capture2e(cmdline)
          Logger.debug o unless o.empty?
          e.success?
        end
      end
    end
  end
end
