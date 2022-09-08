module Yoda
  module Store
    module Objects
      class Map

        # @return [String]
        attr_reader :path

        # @return [Adapter]
        attr_reader :adapter

        # @return [Hash]
        attr_reader :cache

        # @return [Set]
        attr_reader :updated_keys

        # @param adapter [Adapters::Base]
        # @param path [String]
        def initialize(adapter:, path:)
          @adapter = adapter
          @path = path
          @cache = {}
          @updated_keys = Set.new
        end

        def separator
          '::'
        end

        def []=(key, value)
          updated_keys.add(key.to_sym)
          cache[key.to_sym] = value
        end

        def [](key)
          cache.fetch(key.to_sym) do
            cache[key.to_sym] = adapter.get(path_for(key))
          end
        end

        def save
          adapter.batch_write(updated_keys.map { |key| [path_for(key), self[key.to_sym]] })
        end

        def keys
          @adapter_keys ||= adapter.keys.select { |key| key.start_with?("#{path}#{separator}") }.map { |key| key.slice(("#{path}#{separator}".length)..-1).to_sym }
          Set.new(@adapter_keys) + updated_keys
        end

        private

        def path_for(key)
          "#{path}#{separator}#{key}"
        end
      end
    end
  end
end
