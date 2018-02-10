require 'yard'

module Yoda
  module Store
    class Registry
      # @return [Adapters::LeveldbAdapter, nil]
      attr_reader :adapter

      # @param adapter [Adapters::LeveldbAdapter]
      attr_writer :adapter

      # @return [Objects::PatchSet]
      attr_reader :patch_set

      def initialize(adapter = nil)
        @patch_set = Objects::PatchSet.new
        @adapter = adapter
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

      def compress_and_save
        return unless adapter
        keys.each do |key|
          adapter.put(key, find(key))
        end
        @patch_set = Objects::PatchSet.new
      end

      private

      def keys
        Set.new(adapter&.keys.map(&:to_s) || []).union(patch_set.keys)
      end
    end
  end
end
