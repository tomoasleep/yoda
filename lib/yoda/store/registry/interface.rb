module Yoda
  module Store
    class Registry
      module Interface
        # @abstract
        # @param address [String, Symbol]
        # @return [Objects::Addressable]
        def get(address)
          fail NotImplementedError
        end

        # @return [Set<Symbol>]
        def keys
        end
      end
    end
  end
end
