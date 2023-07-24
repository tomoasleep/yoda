module Yoda
  module Store
    module Objects
      module RbsTypes
        class ParameterPosition
          include Serializable

          # @return [Address]
          attr_reader :address

          # @return [Integer]
          attr_reader :index

          # @type (Instance | Hash) -> Instance
          def self.of(type)
            return type if type.is_a?(self)

            build(type)
          end

          # @param address [Address]
          # @param index [Integer]
          def initialize(address:, index:)
            @address = Address.of(address)
            @index = index
          end

          # @return [Hash]
          def to_h
            {
              address: address.to_s,
              index: index,
            }
          end
        end
      end
    end
  end
end
