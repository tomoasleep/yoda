require 'set'

module Yoda
  module Store
    module Types
      class UnionType < Base
        attr_reader :types

        # @param types [Array<Base>]
        # @return [Base]
        def self.new(types)
          types = types.reject { |type| type.is_a? AnyType }
          return AnyType.new if types.length == 0
          return types.first if types.length == 1
          super(types)
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
      end
    end
  end
end
