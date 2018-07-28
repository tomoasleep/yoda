module Yoda
  module Store
    module Actions
      # @todo Build index without using shell script
      class BuildCoreIndex
        class << self
          # @return [true, false]
          def run
            new.run
          end

          def exists?
            [
              "~/.yoda/sources/ruby-#{RUBY_VERSION}/.yardoc",
              "~/.yoda/sources/ruby-#{RUBY_VERSION}/.yardoc-stdlib",
            ].all? { |path| File.exists?(File.expand_path(path)) }
          end
        end

        # @return [true, false]
        def run
          build_core_index
        end

        private

        # @return [String]
        def script_path
          File.expand_path('../../../../scripts/build_core_index.sh', __dir__)
        end

        def build_core_index
          o, e = Open3.capture2e(script_path)
          Logger.debug o unless o.empty?
          if e.success?
            Logger.info "Success to build yard index"
          else
            Logger.warn "Failed to build #{gem_name} #{gem_version}"
          end
        end
      end
    end
  end
end
