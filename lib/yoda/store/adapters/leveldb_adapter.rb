require 'leveldb'

module Yoda
  module Store
    module Adapters
      class LeveldbAdapter
        # @param path [String] represents the path to store db.
        def initialize(path)
          @path = path
          @db = LevelDB::DB.new(path, compression: true)
        end

        # @param address [String]
        # @return [any]
        def get(address)
          @db.get(address.to_s)
        end

        # @param address [String]
        # @param object [Object]
        # @return [void]
        def put(address, object)
          @db.put(address.to_s, object)
        end

        # @param address [String]
        # @return [void]
        def delete(address)
          @db.delete(address.to_s)
        end

        # @param address [String]
        # @return [true, false]
        def exist?(address)
          @db.exist?(address.to_s)
        end

        # @param range_begin [String]
        # @param range_end [String]
        # @return [Enumerable{ String => Object }]
        def range(range_begin, range_end)
          @db.range(range_begin, range_end)
        end

        # @return [Array<String>]
        def keys
          @db.keys
        end

        def stats
          @db.stats
        end
      end
    end
  end
end
