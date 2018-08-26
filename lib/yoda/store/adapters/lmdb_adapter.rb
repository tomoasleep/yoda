require 'lmdb'
require 'json'

module Yoda
  module Store
    module Adapters
      class LmdbAdapter < Base
        class << self
          def for(path)
            @pool ||= {}
            @pool[path] || (@pool[path] = new(path))
          end

          def type
            :lmdb
          end
        end

        # @param path [String] represents the path to store db.
        def initialize(path)
          Dir.mkdir(path) unless Dir.exist?(path)
          @path = path
          @env = LMDB.new(path)
          @db = @env.database('main', create: true)

          at_exit { @env.close }
        end

        # @param address [String]
        # @return [any]
        def get(address)
          JSON.load(@db.get(address.to_s), symbolize_names: true)
        end

        # @param data [Enumerator<(String, Object)>]
        # @param bar [#increment, nil]
        def batch_write(data, bar)
          env = LMDB.new(@path, mapsize: @env.info[:mapsize], writemap: true, mapasync: true, nosync: true)
          db = env.database('main', create: true)
          data.each do |(k, v)|
            begin
              db.put(k.to_s, v.to_json)
            rescue LMDB::Error::MAP_FULL => _ex
              @env.mapsize = @env.info[:mapsize] * 2
              env.close
              env = LMDB.new(@path, mapsize: @env.info[:mapsize], writemap: true, mapasync: true, nosync: true)
              db = env.database('main', create: true)
              db.put(k.to_s, v.to_json)
            end
            bar&.increment
          end
          env.close
        end

        # @param address [String]
        # @param object [Object]
        # @return [void]
        def put(address, object)
          do_put(address.to_s, object.to_json)
        end

        # @param address [String]
        # @return [void]
        def delete(address)
          @db.delete(address.to_s)
        end

        # @param address [String]
        # @return [true, false]
        def exist?(address)
          !!@db.get(address.to_s)
        end

        # @return [Array<String>]
        def keys
          Enumerator.new do |yielder|
            @db.each { |(k, v)| yielder << k }
          end.to_a
        end

        def stats
          @db.stat
        end

        def clear
          @db.clear
        end

        def sync
          # @env.sync(force: true)
        end

        private

        # @param address [String]
        # @param value [String]
        # @return [void]
        def do_put(address, value)
          LMDB.new(@path, mapsize: @env.info[:mapsize]) do |env|
            db = env.database('main', create: true)
            db.put(address, value)
          end
        rescue LMDB::Error::MAP_FULL => _ex
          @env.mapsize = @env.info[:mapsize] * 2
          LMDB.new(@path, mapsize: @env.info[:mapsize]) do |env|
            db = env.database('main', create: true)
            db.put(address, value)
          end
        end
      end
    end
  end
end
