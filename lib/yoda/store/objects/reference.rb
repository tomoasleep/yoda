module Yoda
  module Store
    module Objects
      class Reference
        include Serializable

        # @param base [String, Symbol, Hash]
        def self.of(base)
          case base
          when String, Symbol
            Reference.new(address: Address.of(base))
          else
            Reference.new(**base)
          end
        end

        # @return [Address]
        attr_reader :address

        # @param address [Address]
        def initialize(address: nil)
          @address = Address.of(address)
        end

        def to_h
          {
            address: address,
          }
        end
      end
    end
  end
end
