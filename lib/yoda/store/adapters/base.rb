module Yoda
  module Store
    module Adapters
      # @abstract
      class Base
        # @abstract
        def self.for(path)
          fail NotImplementedError
        end

        # @abstract
        def self.type
          fail NotImplementedError
        end

        # @param path [String, nil]
        def self.path_for(path)
          path ? "#{path}.#{type}" : nil
        end

        # @abstract
        # @param address [String, Symbol]
        # @return [Object, nil]
        def get(address)
          fail NotImplementedError
        end

        # @abstract
        # @param address [String, Symbol]
        # @param object [Object]
        # @return [void]
        def put(address, object)
          fail NotImplementedError
        end

        # @abstract
        # @param address [String, Symbol]
        # @return [void]
        def delete(address)
          fail NotImplementedError
        end

        # @abstract
        # @param address [String, Symbol]
        # @return [Boolean]
        def exist?(address)
          fail NotImplementedError
        end

        # @abstract
        # @return [Integer]
        def keys
          fail NotImplementedError
        end

        # @abstract
        # @return [Object]
        def stats
          fail NotImplementedError
        end

        # @abstract
        # @return [void]
        def sync
          fail NotImplementedError
        end

        # Clear all contents in the database.
        # @abstract
        # @return [void]
        def clear
          fail NotImplementedError
        end

        # @abstract
        # @return [Boolean]
        def empty?
          fail NotImplementedError
        end

        # @abstract
        # @param name [String, Symbol]
        # @return [Base]
        def namespace(name)
          fail NotImplementedError
        end

        # @abstract
        # @return [Boolean]
        def persistable?
          fail NotImplementedError
        end

        # @param data [Enumerator<(String, Object)>]
        # @param bar [#increment, nil]
        # @abstract
        def batch_write(data, bar)
          fail NotImplementedError
        end

        # @return [String]
        def inspect
          "#<#{self.class.name}: #{self.class.type}>"
        end
      end
    end
  end
end
