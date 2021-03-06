require 'set'

module Yoda
  module Model
    module TypeExpressions
      class UnionType < Base
        attr_reader :types

        # @param types [Array<Base>]
        # @return [Base]
        def self.new(types)
          reduced_types = types.reject { |type| type.is_a?(AnyType) || type.is_a?(UnknownType) }.uniq
          return (types.first || AnyType.new) if reduced_types.length == 0
          return reduced_types.first if reduced_types.length == 1
          super(reduced_types)
        end

        # @param types [Array<Base>]
        def initialize(types)
          @types = types
        end

        def eql?(another)
          another.is_a?(UnionType) && Set.new(types) == Set.new(another.types)
        end

        def hash
          [self.class.name, Set.new(types)].hash
        end

        # @param paths [Array<Path>]
        # @return [self]
        def change_root(paths)
          self.class.new(types.map { |type| type.change_root(paths) })
        end

        # @param registry [Registry]
        # @return [Array<Store::Objects::Base>]
        def resolve(registry)
          types.map { |type| type.resolve(registry) }.flatten.compact
        end

        # @return [String]
        def to_s
          types.map(&:to_s).join(' | ')
        end

        # @param env [Environment]
        def to_rbs_type(env)
          RBS::Types::Union.new(types: types.map { |t| t.to_rbs_type(env) }, location: nil)
        end

        # @return [self]
        def map(&block)
          self.class.new(types.map(&block))
        end
      end
    end
  end
end
