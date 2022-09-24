module Yoda
  module Store
    module Adapters
      class SqliteAdapter
        class NamespaceAccessor
          # @return [DatabaseAccessor]
          attr_reader :database_accessor

          # @return [String, nil]
          attr_reader :namespace

          # @param database_accessor [DatabaseAccessor]
          # @param namespace [String, Symbol, nil]
          def initialize(database_accessor:, namespace:)
            @database_accessor = database_accessor
            @namespace = namespace&.to_s
          end

          # @param address [String, Symbol]
          # @return [Object, nil]
          def get(address, **)
            database_accessor.find_first(namespace_key, address)
          end

          # @param address [String, Symbol]
          # @param object [#to_json]
          # @return [void]
          def put(address, object, **)
            database_accessor.replace(namespace_key, address, object)
          end

          # @param address [String, Symbol]
          # @return [void]
          def delete(address)
            database_accessor.delete_object(namespace_key, address)
          end

          # @abstract
          # @param address [String, Symbol]
          # @return [Boolean]
          def exist?(address)
            database_accessor.has_key?(namespace_key, address)
          end

          # @abstract
          # @return [Array<String>]
          def keys
            database_accessor.keys(namespace_key)
          end

          # @abstract
          # @return [Object]
          def stats
            {}
          end

          # @abstract
          # @return [void]
          def sync
            # nop
          end

          # Clear all contents in the database.
          # @abstract
          # @return [void]
          def clear
            if namespace
              database_accessor.delete_namespace(namespace_key)
            else
              database_accessor.delete_all
            end
          end

          # @abstract
          # @return [Boolean]
          def empty?
            if namespace
              database_accessor.size_of(namespace) == 0
            else
              database_accessor.all_size == 0
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
          def batch_write(data, *)
            database_accessor.replace_multiple(namespace_key, data)
          end

          # @return [String]
          def inspect
            "#<#{self.class.name}: #{namespace}>"
          end

          # @param pp [PP]
          def pretty_print(pp)
            pp.object_group(self) do
              pp.breakable
              pp.text "@database_accessor="
              pp.pp adapter
              pp.breakable
              pp.text "@namespace="
              pp.pp namespace
            end
          end

          private

          # @return [String]
          def namespace_key
            namespace&.to_s || ''
          end
        end
      end
    end
  end
end
