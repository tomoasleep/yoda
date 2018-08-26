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

        # @abstract
        def get(address)
          fail NotImplementedError
        end

        # @abstract
        def put(address, object)
          fail NotImplementedError
        end

        # @abstract
        def delete(address)
          fail NotImplementedError
        end

        # @abstract
        def exist?(address)
          fail NotImplementedError
        end

        # @abstract
        def keys
          fail NotImplementedError
        end

        # @abstract
        def stats
          fail NotImplementedError
        end

        # @abstract
        def sync
          fail NotImplementedError
        end

        # @abstract
        def clear
          fail NotImplementedError
        end

        # @param data [Enumerator<(String, Object)>]
        # @param bar [#increment, nil]
        # @abstract
        def batch_write(data, bar)
        end
      end
    end
  end
end
