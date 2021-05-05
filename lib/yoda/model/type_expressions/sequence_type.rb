module Yoda
  module Model
    module TypeExpressions
      class SequenceType < Base
        attr_reader :base_type, :types

        # @param base_type [Base]
        # @param types [Array<Base>]
        def initialize(base_type, types)
          @base_type = base_type
          @types = types
        end

        def name
          base_type.name
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(SequenceType) &&
          base_type  == another.base_type &&
          types == another.types
        end

        def hash
          [self.class.name, base_type, types].hash
        end

        # @param paths [Array<Path>]
        # @return [self]
        def change_root(paths)
          self.class.new(base_type.change_root(paths), types.map { |type| type.change_root(paths) })
        end

        # @param registry [Registry]
        # @return [Array<Store::Objects::Base>]
        def resolve(registry)
          base_type.resolve(registry)
        end

        # @return [String]
        def to_s
          "#{base_type}(#{types.map(&:to_s).join(', ')})"
        end

        # @param env [Environment]
        def to_rbs_type(env)
          RBS::Types::Tuple.new(types: types.map { |t| t.to_rbs_type(env) }, location: nil)
        end

        # @return [self]
        def map(&block)
          self.class.new(base_type.map(&block), types.map(&block))
        end
      end
    end
  end
end
