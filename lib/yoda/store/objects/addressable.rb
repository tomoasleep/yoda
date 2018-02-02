module Yoda
  module Store
    module Objects
      module Addressable
        # @abstract
        # @return [Symbol]
        def type
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def address
          fail NotImplementedError
        end

        # @abstract
        # @return [Hash]
        def to_hash
          fail NotImplementedError
        end
      end
    end
  end
end
