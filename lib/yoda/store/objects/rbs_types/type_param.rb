require 'yoda/store/objects/connected_delegation'

module Yoda
  module Store
    module Objects
      module RbsTypes
        class TypeParam
          include Serializable

          # @return [Symbol]
          attr_reader :name

          # @return [Boolean]
          attr_reader :unchecked

          # @return [:invariant, :covariant, :contravariant]
          attr_reader :variance

          # @return [NamespaceAccess, nil]
          attr_reader :upper_bound

          # @param name [Symbol]
          # @param unchecked [Boolean]
          # @param variance [:invariant, :covariant, :contravariant]
          # @param upper_bound [Symbol, nil]
          def initialize(
            name:,
            unchecked: false,
            variance: :invariant,
            upper_bound: nil
          )
            @name = name.to_sym
            @unchecked = unchecked
            @variance = variance
            @upper_bound = upper_bound&.yield_self(&NamespaceAccess.method(:build))
          end

          # @return [Hash]
          def to_h
            {
              name: name,
              unchecked: unchecked,
              variance: variance,
              upper_bound: upper_bound&.to_h,
            }
          end
        end
      end
    end
  end
end
