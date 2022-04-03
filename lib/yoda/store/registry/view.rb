module Yoda
  module Store
    module Registry
      class View
        # @return [Registry::Composer]
        attr_reader :composer

        # @return [IdMask]
        attr_reader :mask

        # @param composer [Registry::Composer]
        # @param mask [IdMask]
        def initialize(composer:, mask:)
          @composer = composer
          @mask = mask
        end

        # @param key [String, Symbol]
        # @return [Object]
        def get(key, **args)
          registry.get(key, registry_ids: mask)
        end

        # @param key [String, Symbol]
        # @return [Boolean]
        def has_key?(key, **args)
          !!registry.get(key, registry_ids: mask)
        end

        def keys
          registry.keys
        end

        def clear_cache
          registry.clear_cache
        end

        private

        # @return [Registry::Cache::RegistryWrapper]
        def registry
          @registry ||= Registry::Cache::RegistryWrapper.new(composer)
        end
      end
    end
  end
end
