require 'zip'
require 'open-uri'
require 'fileutils'

module Yoda
  module Store
    module Actions
      class BuildCoreIndex
        class << self
          # @return [true, false]
          def run
            new.run
          end

          def exists?
            [
              VersionStore.for_current_version.core_yardoc_path,
              VersionStore.for_current_version.stdlib_yardoc_path,
            ].all? { |path| File.exists?(path) }
          end
        end

        # @return [true, false]
        def run
          Logger.info "Downloading ruby source"
          download_core_index_file
          Logger.info "Building ruby core and stdlib index"
          build_core_index
        end

        private

        def ruby_version_major_minor
          RUBY_VERSION.sub(/^(\d+)\.(\d+)\.\d+$/, '\\1.\\2')
        end

        def download_core_index_file
          Zip.warn_invalid_date = false

          URI.open("https://cache.ruby-lang.org/pub/ruby/#{ruby_version_major_minor}/ruby-#{RUBY_VERSION}.zip") do |file|
            Zip::File.open_buffer(file) do |zip_file|
              zip_file.each do |entry|
                # entry path already include `ruby-#{RUBY_VERSION}/``
                extracted_entry_path = File.join(VersionStore.for_current_version, "../", entry.to_s)
                FileUtils.mkdir_p(File.dirname(extracted_entry_path))
                zip_file.extract(entry, extracted_entry_path) { true }
              end
            end
          end
        end

        def build_core_index
          Dir.chdir(VersionStore.for_current_version.ruby_source_path) do
            exec_yardoc("yard doc -n *.c") || return
            exec_yardoc("yard doc -b .yardoc-stdlib -o doc-stdlib -n") || return
          end
          Logger.info "Success to build yard index"
        end

        def exec_yardoc(cmdline)
          o, e = Open3.capture2e(cmdline)
          Logger.debug o unless o.empty?
          if e.success?
            true
          else
            Logger.warn "Failed to build core index"
            false
          end
        end
      end
    end
  end
end
