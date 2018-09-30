require 'concurrent'

module Yoda
  module Store
    # Registry Cache is a cache layer for {Registry}.
    # This class intended to reduce patch calculations of {PatchSet#patch}.
    class RegistryCache
      def initialize
        @data = Concurrent::Map.new
      end

      # @param key [String, Symbol]
      def fetch_or_calc(key)
        if cache = data.get(key.to_sym)
          return cache
        end
        yield.tap { |value| data.put_if_absent(key.to_sym, value) }
      end

      # @param key [String, Symbol]
      def delete(key)
        data.delete(key.to_sym)
      end

      def delete_all
        data.clear
      end

      # @param patch [Objects::Patch]
      def clear_from_patch(patch)
        patch.keys.each { |key| delete(key) }
      end

      private

      # @return [Concurrent::Map]
      attr_reader :data
    end
  end
end
