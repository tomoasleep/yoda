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

          # @param params [Array<TypeParam, Hash>]
          # @return [Array<TypeParam>]
          def self.multiple_of(params)
            params.map { |param| of(param) }
          end

          # @param param [TypeParam, Hash, RBS::AST::TypeParam]
          def self.of(param)
            return param if param.is_a?(self)
            if param.is_a?(RBS::AST::TypeParam)
              return new(
                name: param.name,
                variance: param.variance,
                upper_bound: param.upper_bound&.name,
                unchecked: param.unchecked?,
              )
            end

            new(**param)
          end

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
            @upper_bound = upper_bound&.yield_self(&NamespaceAccess.method(:of))
          end

          # @param name [Symbol]
          # @param new_name [Symbol]
          # @return [self]
          def rename_variable(name, new_name)
            if self.name == name
              TypeParam.new(
                name: new_name,
                unchecked: unchecked,
                upper_bound: upper_bound,
                variance: variance,
              )
            else
              self
            end
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
