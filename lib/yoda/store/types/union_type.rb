require 'set'

module Yoda
  module Store
    module Types
      class UnionType < Base
        attr_reader :types

        def self.new(types)
          typs = types.reject { |type| type.is_a? AnyType }
          return AnyType.new if types.length == 0
          return types.first if types.length == 1
          super(types)
        end

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
      end
    end
  end
end
