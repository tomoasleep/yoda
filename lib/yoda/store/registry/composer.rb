module Yoda
  module Store
    class Registry::Composer 
      # @return [Symbol]
      attr_reader :id

      # @return [Hash{Symbol => Registry}]
      attr_reader :registries

      def initialize(id:, registries: [])
        @id = id
        @registries = registries.map { |registry| [registry.id.to_sym, registry] }.to_h
      end

      def add_registry(registry)
        registries[registry.id.to_sym] = registry
      end

      def remove_registry(registry)
        registries.delete(registry.id.to_sym)
      end

      def get(address, registry_ids: nil)
        registry_mask = IdMask.build(registry_ids)
        target_registries = registry_mask.any? ? all_registries : registry_mask.covering_ids.map { |id| get_registry(id) }.compact

        objects_in_registry = target_registries.map { |registry| registry.get(address, registry_ids: registry_mask.nesting_mask(registry.id)) }.compact
        objects_in_registry.empty? ? nil : Objects::Merger.new(objects_in_registry).merged_instance
      end

      # @return [Set]
      def keys
        registries.values.map(&:keys).reduce(Set.new) { |memo, keys| memo + keys }
      end

      def get_registry(key)
        registries[key.to_sym]
      end

      def has_registry(key)
        registries.has_key?(key.to_sym)
      end

      def all_registries
        registries.values.compact
      end
    end
  end
end
