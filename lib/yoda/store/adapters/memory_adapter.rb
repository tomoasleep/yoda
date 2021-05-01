require 'json'

module Yoda
  module Store
    module Adapters
      # An adapter implementation to store object in memory.
      # This implementation losts data on exit and we recommend to use this adapter only for test.
      class MemoryAdapter < Base
        class << self
          def for(path)
            @pool ||= {}
            @pool[path] || (@pool[path] = new(path))
          end

          def type
            :memory
          end
        end

        # @return [Hash{String => String}]
        attr_reader :db

        # @param path [String, nil] represents the path to store db.
        def initialize(path = nil)
          @path = path
          @db = {}
        end

        # @param address [String]
        # @return [any]
        def get(address)
          JSON.load(db[address.to_s], symbolize_names: true)
        end

        # @param data [Enumerator<(String, Object)>]
        # @param bar [#increment, nil]
        def batch_write(data, bar)
          data.each do |(k, v)|
            put(k, v)
            bar&.increment
          end
        end

        # @param address [String]
        # @param object [Object]
        # @return [void]
        def put(address, object)
          db[address.to_s] = object.to_json
        end

        # @param address [String]
        # @return [void]
        def delete(address)
          db.delete(address.to_s)
        end

        # @param address [String]
        # @return [true, false]
        def exist?(address)
          db.member?(address.to_s)
        end

        # @param name [String]
        # @return [MemoryAdapter]
        def namespace(name)
          namespaces[name.to_s] ||= MemoryAdapter.new
        end

        # @return [Array<String>]
        def keys
          db.keys
        end

        def stats
          "No stats"
        end

        def clear
          db.clear
        end

        def sync
        end

        private

        # @return [Hash{String => MemoryAdapter}]
        def namespaces
          @namespaces ||= {}
        end
      end
    end
  end
end
