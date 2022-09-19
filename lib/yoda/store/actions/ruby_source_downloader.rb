require 'zip'
require 'open-uri'
require 'fileutils'

module Yoda
  module Store
    module Actions
      class RubySourceDownloader
        class << self
          # @return [true, false]
          def run
            new.run
          end

          # @return [true, false]
          def downloaded?
            File.exists?(VersionStore.for_current_version.ruby_source_path)
          end
        end

        # @return [true, false]
        def run
          Logger.info "Downloading ruby source"
          download_core_index_file
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
                extracted_entry_path = File.join(VersionStore.for_current_version.ruby_source_path, "../", entry.to_s)
                FileUtils.mkdir_p(File.dirname(extracted_entry_path))
                zip_file.extract(entry, extracted_entry_path) { true }
              end
            end
          end
        end
      end
    end
  end
end
