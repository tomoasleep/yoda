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
          updated_keys.add(key)
          cache[key] = value
        end

        def [](key)
          cache.fetch(key) do
            cache[key] = adapter.get(path_for(key))
          end
        end

        def save
          updated_keys.each do |key|
            adapter.put(path_for(key), self[key])
          end
        end

        def keys
          @adapter_keys ||= adapter.keys.select { |key| key.start_with?("#{path}#{separator}") }
          Set.new(@adapter_keys + updated_keys)
        end

        private

        def path_for(key)
          "#{path}#{separator}#{key}"
        end
      end
    end
  end
end
