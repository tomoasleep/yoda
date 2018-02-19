require 'leveldb'
require 'json'

module Yoda
  module Store
    module Adapters
      class LeveldbAdapter < Base
        class << self
          def for(path)
            @pool ||= {}
            @pool[path] || (@pool[path] = new(path))
          end

          def type
            :leveldb
          end
        end

        # @param path [String] represents the path to store db.
        def initialize(path)
          @path = path
          @db = LevelDB::DB.new(path, compression: true)

          at_exit { @db.closed? || @db.close }
        end

        # @param address [String]
        # @return [any]
        def get(address)
          JSON.load(@db.get(address.to_s), symbolize_names: true)
        end

        # @param address [String]
        # @param object [Object]
        # @return [void]
        def put(address, object)
          @db.put(address.to_s, object.to_json)
        end

        # @param data [Enumerator<(String, Object)>]
        # @param bar [ProgressBar, nil]
        def batch_write(data, bar)
          data.each do |(k, v)|
            @db.put(k, v)
            bar&.increment
          end
        end

        # @param address [String]
        # @return [void]
        def delete(address)
          @db.delete(address.to_s)
        end

        # @param address [String]
        # @return [true, false]
        def exist?(address)
          @db.exists?(address.to_s)
        end

        # @return [Array<String>]
        def keys
          @db.keys
        end

        def stats
          @db.stats
        end

        def clear
          @db.destroy!
        end

        def sync
          # nop
        end
      end
    end
  end
end
