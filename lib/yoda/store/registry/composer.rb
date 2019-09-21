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
        registries.delete[registry.id]
      end

      def get(address, from: nil)
        objects_in_registry = (from || registries.values).map { |registry| registry.get(address) }.compact
        Merger.new(objects_in_patch).merged_instance
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
    end
  end
end