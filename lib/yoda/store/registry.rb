require 'yard'

module Yoda
  module Store
    class Registry
      # @note This number must be updated when breaking change is added.
      REGISTRY_VERSION = 1

      # @return [Adapters::LmdbAdapter, nil]
      attr_reader :adapter

      # @return [Objects::PatchSet]
      attr_reader :patch_set

      PROJECT_STATUS_KEY = '%project_status'

      def initialize(adapter = nil)
        @patch_set = Objects::PatchSet.new
        @adapter = adapter
      end

      # @return [Objects::ProjectStatus, nil]
      def project_status
        adapter&.exist?(PROJECT_STATUS_KEY) && adapter.get(PROJECT_STATUS_KEY)
      end

      # @param new_project_status [Objects::ProjectStatus]
      def save_project_status(new_project_status)
        adapter.put(PROJECT_STATUS_KEY, new_project_status)
      end

      # @param path [String]
      # @return [Objects::Base, nil]
      def find(path)
        if adapter&.exist?(path)
          patch_set.patch(adapter.get(path))
        else
          patch_set.find(path)
        end
      end

      # @param patch [Patch]
      def add_patch(patch)
        patch_set.register(patch)
      end

      # @param path [String]
      # @return [true, false]
      def has_key?(path)
        adapter&.exists?(path) || patch_set.has_key?(path)
      end

      def clear
        lock.with_write_lock do
          adapter.clear
        end
      end

      # Store patch set data to the database.
      # old data in the database are discarded.
      def compress_and_save
        return unless adapter
        el_keys = patch_set.keys
        progress = Instrument::Progress.new(el_keys.length) { |length:, index:| Instrument.instance.registry_dump(index: index, length: length) }

        data = Enumerator.new do |yielder|
          el_keys.each { |key| yielder << [key, patch_set.find(key)] }
        end

        adapter.batch_write(data, progress)
        adapter.sync
        Logger.info "saved #{el_keys.length} keys."
        @patch_set = Objects::PatchSet.new
      end

      private

      def keys
        Set.new(adapter&.keys.map(&:to_s) || []).union(patch_set.keys)
      end
    end
  end
end
