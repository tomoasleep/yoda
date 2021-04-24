require 'zip'
require 'open-uri'
require 'fileutils'

module Yoda
  module Store
    module Actions
      class BuildCoreIndex
        SOURCE_PATH = File.expand_path("~/.yoda/sources")
        VERSION_DIR_NAME = "ruby-#{RUBY_VERSION}"
        VERSION_SOURCE_PATH = File.join(SOURCE_PATH, VERSION_DIR_NAME)

        class << self
          # @return [true, false]
          def run
            new.run
          end

          def exists?
            [
              File.expand_path(VERSION_SOURCE_PATH, '.yardoc'),
              File.expand_path(VERSION_SOURCE_PATH, '.yardoc-stdlib'),
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
                extracted_entry_path = File.join(SOURCE_PATH, entry.to_s)
                FileUtils.mkdir_p(File.dirname(extracted_entry_path))
                zip_file.extract(entry, extracted_entry_path) { true }
              end
            end
          end
        end

        def build_core_index
          Dir.chdir(VERSION_SOURCE_PATH) do
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
