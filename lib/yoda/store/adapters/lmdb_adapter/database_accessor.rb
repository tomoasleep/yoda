

module Yoda
  module Store
    module Adapters
      class LmdbAdapter
        class DatabaseAccessor
          # @return [LmdbAdapter]
          attr_reader :adapter

          # @param adapter [LmdbAdapter]
          # @param database_name [String, #to_s]
          def initialize(adapter, database_name)
            @adapter = adapter
            @database_name = database_name.to_s
          end

          # @param address [String]
          # @return [any]
          def get(address)
            JSON.load(database.get(address.to_s), symbolize_names: true)
          end

          # @param data [Enumerator<(String, Object)>]
          # @param bar [#increment, nil]
          def batch_write(data, bar)
            data.each do |(k, v)|
              adapter.with_auto_map_resize do
                database.put(k.to_s, v.to_json)
                bar&.increment
              end
            end
          end

          # @param address [String]
          # @param object [Object]
          # @return [void]
          def put(address, object)
            adapter.with_auto_map_resize do
              database.put(address.to_s, object.to_json)
            end
          end

          # @param address [String]
          # @return [void]
          def delete(address)
            database.delete(address.to_s)
          end

          # @param address [String]
          # @return [Boolean]
          def exist?(address)
            !!database.get(address.to_s)
          end

          # @return [Boolean]
          def empty?
            database.stat[:entries] == 0
          end

          # @return [Array<String>]
          def keys
            Enumerator.new do |yielder|
              database.each { |(k, v)| yielder << k }
            end.to_a
          end

          # @return [Hash]
          def stats
            database.stat
          end

          def clear
            database.clear
          end

          private

          # @return [LMDB::Database]
          def database
            @adapter.database_for(@database_name)
          end
        end
      end
    end
  end
end
