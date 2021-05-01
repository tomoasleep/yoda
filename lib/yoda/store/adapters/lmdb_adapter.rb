require 'lmdb'
require 'json'
require 'fileutils'
require 'forwardable'

module Yoda
  module Store
    module Adapters
      class LmdbAdapter < Base
        require 'yoda/store/adapters/lmdb_adapter/database_accessor'

        class << self
          def for(path)
            @pool ||= {}
            @pool[path] || (@pool[path] = new(path))
          end

          def type
            :lmdb
          end
        end

        attr_reader :maxdbs

        extend Forwardable
        delegate [:get, :batch_write, :put, :delete, :exists, :keys] => :main_namespace

        # @param path [String] represents the path to store db.
        def initialize(path)
          FileUtils.mkdir_p(path) unless Dir.exist?(path)
          @path = path
          @maxdbs = 4
          @env = LMDB.new(@path, **environment_options)

          at_exit { @env.close }
        end

        def reopen(maxdbs: nil, **kwargs)
          info_options = @env.info.slice(:mapsize, :maxreaders)
          @env.close
          databases.clear
          @maxdbs = maxdbs if maxdbs
          @env = LMDB.new(@path, **environment_options, **info_options, **kwargs)
        end

        def stats
          @env.stat
        end

        def clear
          main_namespace.clear
          # TOOD: Implement
        end

        def sync
          # TOOD: Implement
        end

        # @param namespace [String]
        # @return [DatabaseAccessor]
        def namespace(name)
          DatabaseAccessor.new(self, name)
        end

        def database_for(name)
          with_auto_db_resize do
            databases[name] ||= @env.database(name, create: true)
          end
        end

        def with_auto_map_resize
          yield
        rescue LMDB::Error::MAP_FULL => _ex
          # After once failed, transaction always fails, so reopen with the new config instead of updating mapsize.
          # @env.mapsize = @env.info[:mapsize] * 2
          reopen(mapsize: @env.info[:mapsize] * 2)
          yield
        end

        def transaction(*args, &block)
          @env.transaction(*args, &block)
        end

        private

        def main_namespace
          namespace("main")
        end

        def environment_options
          { writemap: true, mapasync: true, nosync: true, maxdbs: @maxdbs }
        end

        def with_auto_db_resize
          yield
        rescue LMDB::Error::DBS_FULL
          reopen(maxdbs: maxdbs * 2)
          yield
        end

        # @return [Hash{String => LMDB::Database}]
        def databases
          @databases ||= {}
        end
      end
    end
  end
end
