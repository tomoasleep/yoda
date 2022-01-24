module Yoda
  module Store
    module Adapters
      class GdbmAdapter
        class NamespaceAccessor
          KEYS_ADDRESS = "%keys"

          # @return [GDBM]
          attr_reader :database

          # @return [String, nil]
          attr_reader :namespace

          # @param database [GDBM]
          # @param namespace [String, Symbol, nil]
          def initialize(database:, namespace:)
            @database = database
            @namespace = namespace&.to_s
          end

          # @param address [String, Symbol]
          # @return [Object, nil]
          def get(address)
            JSON.load(database[build_key(address)], symbolize_names: true)
          end

          # @param address [String, Symbol]
          # @param object [#to_json]
          # @return [void]
          def put(address, object, modify_keys: true)
            database[build_key(address)] = object.to_json
            add_addresses([address]) if modify_keys
          end

          # @param address [String, Symbol]
          # @return [void]
          def delete(address)
            database.delete(build_key(address))
          end

          # @abstract
          # @param address [String, Symbol]
          # @return [Boolean]
          def exist?(address)
            database.has_key?(build_key(address))
          end

          # @abstract
          # @return [Integer]
          def keys
            if namespace
              get(KEYS_ADDRESS) || []
            else
              database.keys
            end
          end

          # @abstract
          # @return [Object]
          def stats
            {}
          end

          # @abstract
          # @return [void]
          def sync
            database.sync
          end

          # Clear all contents in the database.
          # @abstract
          # @return [void]
          def clear
            if namespace
              keys.each do |key|
                delete(key)
              end
              delete(KEYS_ADDRESS)
            else
              database.clear
            end
          end

          # @abstract
          # @return [Boolean]
          def empty?
            if namespace
              keys.empty?
            else
              database.empty?
            end
          end

          # @abstract
          # @return [Boolean]
          def persistable?
            true
          end

          # @param data [Enumerator<(String, Object)>]
          # @param bar [#increment, nil]
          # @abstract
          def batch_write(data, bar)
            data.each do |(k, v)|
              put(k, v, modify_keys: false)
              bar&.increment
            end
            add_addresses(data.map(&:first).map(&:to_s).compact)
          end

          # @return [String]
          def inspect
            "#<#{self.class.name}: #{self.class.type}>"
          end

          private

          def add_addresses(new_addresses)
            return unless namespace
            # not locked
            database[build_key(KEYS_ADDRESS)] = (Set.new(keys) + new_addresses).to_a.to_json
          end

          # @param address [String, Symbol]
          # @param [String]
          def build_key(address)
            if namespace
              [namespace, address.to_s].join("/")
            else
              address.to_s
            end
          end

          # @param key [String]
          # @param [String, nil]
          def remove_namespace_from_key(key)
            if namespace
              prefix = "#{namespace}/"
              if key.start_with?(prefix)
                key.delete_prefix(prefix)
              else
                nil
              end
            else
              key
            end
          end
        end
      end
    end
  end
end
