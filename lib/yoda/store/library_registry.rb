module Yoda
  module Store
    class LibraryRegistry
      class << self
        # @param library_dependency [Project::Dependnecy::Library]
        def create_from_patch(library_dependency, patch)
          if File.exists?(library_dependency.registry_path)
            for_library(library_dependency, patch)
          else
            adapter = Adapters.for(library_dependency.registry_path)
            compress_and_save(patch: patch, adapter: adapter)
            new(id: library_dependency.id, adapter: adapter)
          end
        end

        # @param library_dependency [Project::Dependnecy::Library]
        def for_library(library_dependency)
          return unless File.exists?(library_dependency.registry_path)
          adapter = Adapters.for(library_dependency.registry_path)
          new(id: library_dependency.id, adapter: adapter)
        end

        private

        # Store patch set data to the database.
        # old data in the database are discarded.
        def compress_and_save(patch:, adapter:)
          el_keys = patch.keys
          progress = Instrument::Progress.new(el_keys.length) { |length:, index:| Instrument.instance.registry_dump(index: index, length: length) }

          data = Enumerator.new do |yielder|
            el_keys.each { |key| yielder << [key, patch.get(key)] }
          end

          adapter.batch_write(data, progress)
          adapter.sync
          Logger.info "saved #{el_keys.length} keys."
        end
      end

      # @param id [String]
      # @param adapter [Adapters::Base]
      def initialize(id:, adapter:)
        @id
        @adapter = adapter
      end

      def get(path)
        adapter.get(path)
      end

      # @param path [String]
      # @return [true, false]
      def has_key?(path)
        adapter.exists?(path)
      end

      def keys
        @keys ||= Set.new(adapter.keys.map(&:to_s) || [])
      end
    end
  end
end