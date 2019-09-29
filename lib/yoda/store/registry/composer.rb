module Yoda
  module Store
    class Registry::Composer 
      # @return [Symbol]
      attr_reader :id

      # @return [Hash{Symbol => Registry}]
      attr_reader :registries

      def initialize(id:, registries: [])
        @id = id
        @registries = registries.map { |registry| [registry.id, registry] }.to_h
      end

      def add_registry(registry)
        registries[registry.id] = registry
      end

      def remove_registry(registry)
        registries.delete(registry.id)
      end

      def get(address, registry_ids: nil)
        target_registries = registry_ids ? registry_ids.map { |id| get_registry(id) }.compact : all_registries
        objects_in_registry = target_registries.map { |registry| registry.get(address) }.compact
        objects_in_registry.empty? ? nil : Objects::Merger.new(objects_in_registry).merged_instance
      end

      # @return [Set]
      def keys
        registries.map(&:keys).reduce(Set.new) { |memo, keys| memo + keys }
      end

      def get_registry(key)
        registries[key]
      end

      def has_registry(key)
        registries.has_key?(key)
      end

      def all_registries
        registries.values.compact
      end
    end
  end
end
