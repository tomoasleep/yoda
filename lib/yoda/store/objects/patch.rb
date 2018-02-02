module Yoda
  module Store
    module Objects
      class Patch
        # @param id [String]
        attr_reader :id

        # @param registry [Hash{ Symbol => Addressable }]
        attr_reader :registry

        # @param id [String]
        def initialize(id)
          @id = id
          @registry = Hash.new
        end

        # @param addressable [Addressable]
        # @return [void]
        def register(addressable)
          @registry[addressable.address.to_sym] = addressable
        end

        # @param address [String, Symbol]
        # @return [Addressable, nil]
        def find(address)
          @registry[address.to_sym]
        end

        # @param address [String, Symbol]
        # @return [true, false]
        def has_key?(address)
          @registry.has_key?(address.to_sym)
        end

        # @return [Array<Symbol>]
        def keys
          @registry.keys
        end
      end
    end
  end
end
