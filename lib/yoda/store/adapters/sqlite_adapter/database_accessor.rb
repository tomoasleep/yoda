require 'sqlite3'
require 'fileutils'

module Yoda
  module Store
    module Adapters
      class SqliteAdapter
        class DatabaseAccessor
          # @return [SQLite3::Database]
          attr_reader :database
          private :database

          class << self
            # @return [DatabaseAccessor]
            def open(path)
              dirname = File.dirname(path)
              FileUtils.mkdir_p(dirname) unless Dir.exist?(dirname)
              file_exists = File.exist?(path)
              database = SQLite3::Database.new(path)
              setup(database) unless file_exists
              new(database)
            end

            def setup(database)
              database.execute <<~SQL
                CREATE TABLE IF NOT EXISTS objects (
                  namespace TEXT NOT NULL,
                  address TEXT NOT NULL,
                  value TEXT NOT NULL,
                  PRIMARY KEY (namespace, address)
                );
              SQL
            end
          end

          # @param database [SQLite3::Database]
          def initialize(database)
            @database = database
          end

          # @param address [String, Symbol]
          # @param namespace [String, Symbol]
          # @return [Object, nil]
          def find_first(namespace, address)
            rows = database.execute("SELECT value FROM objects WHERE namespace = ? AND address = ? LIMIT 1", [namespace.to_s, address.to_s])
            rows.first&.yield_self { |json, _| JSON.load(json) }
          end

          # @param namespace [String, Symbol]
          # @param addresses [Array<String, Symbol>]
          # @return [Hash{String, Symbol => Object, nil}]
          def file_multiple(namespace, addresses)
            rows = database.execute("SELECT address, value FROM objects WHERE namespace = ? AND address in (#{addresses.length.times.map { '?' }.join(', ')})", [namespace.to_s, *addresses.map(&:to_s)])
            rows.map { |address, json| [address, JSON.load(json)] }.to_h
          end

          # @param namespace [String, Symbol]
          # @param address [String, Symbol]
          # @param value [Object]
          # @return [Object, nil]
          def replace(namespace, address, value)
            database.execute("REPLACE INTO objects (namespace, address, value) VALUES (?, ?, ?) ", namespace.to_s, address.to_s, value&.to_json)
          end

          # @param namespace [String, Symbol]
          # @param address_to_values [Enumerator<(Symbol, Object}>]
          # @return [Object, nil]
          def replace_multiple(namespace, address_to_values)
            full_address_to_values = address_to_values.map { |address, value| [namespace.to_s, address.to_s, value&.to_json] }

            # Divide parameters not to exceed SQLITE_MAX_VARIABLE_NUMBER (default is 999)
            # Ref: https://www.sqlite.org/limits.html
            full_address_to_values.each_slice(330) do |chunk_of_address_to_values|
              database.execute("REPLACE INTO objects (namespace, address, value) VALUES #{chunk_of_address_to_values.length.times.map { '(?, ?, ?)' }.join(', ')}", chunk_of_address_to_values.flatten)
            end
          end

          # @param address [String, Symbol]
          # @param namespace [String, Symbol]
          # @return [void]
          def delete_object(namespace, address)
            database.execute("DELETE FROM objects WHERE namespace = ? AND address = ?", namespace.to_s, address.to_s)
          end

          # @return [Array<String>]
          def namespaces
            database.execute("SELECT DISTINCT namespace FROM objects").map(&:first)
          end

          # @param namespace [String, Symbol]
          # @return [Array<String>]
          def keys(namespace)
            database.execute("SELECT address FROM objects WHERE namespace = ?", [namespace.to_s]).map(&:first)
          end

          # @param namespace [String, Symbol]
          # @param address [String, Symbol]
          # @return [Boolean]
          def has_key?(namespace, address)
            row = database.execute("SELECT count(*) FROM objects WHERE namespace = ? AND address = ?", [namespace.to_s, address.to_s])
            count, _ = row.first
            count > 0
          end

          # @param namespace [String, Symbol]
          # @return [void]
          def delete_namespace(namespace)
            database.execute("DELETE FROM objects WHERE namespace = ?", [namespace.to_s])
          end

          # @return [void]
          def delete_all
            database.execute("DELETE FROM objects")
          end

          # @param namespace [String, Symbol]
          # @return [Integer]
          def size_of(namespace)
            row = database.execute("SELECT count(*) FROM objects WHERE namespace = ?", [namespace.to_s])
            count, _ = row.first
            count
          end

          # @return [Integer]
          def all_size
            row = database.execute("SELECT count(*) FROM objects")
            count, _ = row.first
            count
          end

          private
        end
      end
    end
  end
end
