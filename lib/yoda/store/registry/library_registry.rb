module Yoda
  module Store
    class Registry::LibraryRegistry
      class << self
        # @param library [Objects::Library]
        def for_library(library)
          adapter = Adapters.for(library.registry_path)
          namespace = adapter.namespace(library.name)

          if namespace.empty?
            Instrument.instance.build_library_registry(name: library.name, version: library.version, message: "Building registry for #{library.name} (#{library.version})")
            patch = library.create_patch
            patch && compress_and_save(patch: patch, adapter: namespace)
            Instrument.instance.build_library_registry(name: library.name, version: library.version, message: "Finished to build registry for #{library.name} (#{library.version})")
          end

          new(id: library.id, adapter: namespace)
        end

        private

        # Store patch set data to the database.
        # old data in the database are discarded.
        # @param patch [Objects::Patch]
        # @param adapter [Adapters::Base]
        def compress_and_save(patch:, adapter:)
          el_keys = patch.keys
          progress = Instrument::Progress.new(el_keys.length) { |length:, index:| Instrument.instance.registry_dump(index: index, length: length) }

          data = Enumerator.new do |yielder|
            el_keys.each { |key| yielder << [key, patch.get(key)] }
          end

          adapter.batch_write(data, progress)
          Logger.info "saved #{el_keys.length} keys."
        end
      end

      # @return [String]
      attr_reader :id

      # @return [Adapters::Base]
      attr_reader :adapter

      # @param id [String]
      # @param adapter [Adapters::Base]
      def initialize(id:, adapter:)
        @id = id
        @adapter = adapter
      end

      def get(path, **)
        adapter.get(path)
      end

      # @param path [String]
      # @return [true, false]
      def has_key?(path)
        adapter.exists?(path)
      end

      def persistable?
        adapter.persistable?
      end

      def keys
        @keys ||= Set.new(adapter.keys.map(&:to_s) || [])
      end
    end
  end
end
