require 'set'

module Yoda
  module Store
    module Types
      class UnionType < Base
        attr_reader :types

        # @param types [Array<Base>]
        # @return [Base]
        def self.new(types)
          reduced_types = types.reject { |type| type.is_a?(AnyType) || type.is_a?(UnknownType) }
          return (types.first || AnyType.new) if reduced_types.length == 0
          return reduced_types.first if reduced_types.length == 1
          super(reduced_types)
        end

        # @param types [Array<Base>]
        def initialize(types)
          @types = types
        end

        def eql?(another)
          another.is_a?(UnionType) &&
          Set.new(types) == Set.new(another.types)
        end

        def hash
          [self.class.name, Set.new(types)].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [UnionType]
        def change_root(namespace)
          self.class.new(types.map { |type| type.change_root(namespace) })
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          types.map { |type| type.resolve(registry) }.flatten
        end
      end
    end
  end
end
