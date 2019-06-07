require 'concurrent'
require 'yard'

module Yoda
  module Store
    class Registry
      include HasServices

      service(:constant_finder) { Query::FindConstant.new(self) }
      service(:meta_class_finder) { Query::FindMetaClass.new(self) }
      service(:method_finder) { Query::FindMethod.new(self) }
      service(:signature_finder) { Query::FindSignature.new(self) }

      # @note This number must be updated when breaking change is added.
      REGISTRY_VERSION = 2

      PROJECT_STATUS_KEY = '%project_status'

      def initialize(adapter = nil)
        @patch_set = Objects::PatchSet.new
        @adapter = adapter
        @registry_cache = RegistryCache.new
        @lock = Concurrent::ReentrantReadWriteLock.new
      end

      # @return [Objects::ProjectStatus, nil]
      def project_status
        lock.with_read_lock do
          adapter&.exist?(PROJECT_STATUS_KEY) && adapter.get(PROJECT_STATUS_KEY)
        end
      end

      # @param new_project_status [Objects::ProjectStatus]
      def save_project_status(new_project_status)
        lock.with_write_lock do
          adapter.put(PROJECT_STATUS_KEY, new_project_status)
        end
      end

      # @param path [String]
      # @return [Objects::Base, nil]
      def find(path)
        lock.with_read_lock do
          registry_cache.fetch_or_calc(path) do
            if adapter&.exist?(path)
              patch_set.patch(adapter.get(path))
            else
              patch_set.find(path)
            end
          end
        end
      end

      # @param patch [Patch]
      def add_patch(patch)
        lock.with_write_lock do
          registry_cache.clear_from_patch(patch)
          patch_set.register(patch)
        end
      end

      # @param path [String]
      # @return [true, false]
      def has_key?(path)
        lock.with_read_lock do
          adapter&.exists?(path) || patch_set.has_key?(path)
        end
      end

      def clear
        lock.with_write_lock do
          registry_cache.delete_all
          adapter.clear
        end
      end

      # Store patch set data to the database.
      # old data in the database are discarded.
      def compress_and_save
        return unless adapter
        lock.with_write_lock do
          el_keys = patch_set.keys
          progress = Instrument::Progress.new(el_keys.length) { |length:, index:| Instrument.instance.registry_dump(index: index, length: length) }

          data = Enumerator.new do |yielder|
            el_keys.each { |key| yielder << [key, patch_set.find(key)] }
          end

          adapter.batch_write(data, progress)
          adapter.sync
          Logger.info "saved #{el_keys.length} keys."
          @patch_set = Objects::PatchSet.new
          registry_cache.delete_all
        end
      end

      def inspect
        "#<#{self.class.name}: @adapter=#{adapter.inspect}>"
      end

      private

      # @return [Adapters::LmdbAdapter, nil]
      attr_reader :adapter

      # @return [Objects::PatchSet]
      attr_reader :patch_set

      # @return [RegistryCache]
      attr_reader :registry_cache

      # @return [Concurrent::ReentrantReadWriteLock]
      attr_reader :lock

      def keys
        Set.new(adapter&.keys.map(&:to_s) || []).union(patch_set.keys)
      end
    end
  end
end
