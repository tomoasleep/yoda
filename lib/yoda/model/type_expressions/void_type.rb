module Yoda
  module Model
    module TypeExpressions
      class VoidType < Base
        def eql?(another)
          false
        end

        def hash
          [self.class.name].hash
        end

        # @param paths [Array<Paths>]
        # @return [self]
        def change_root(paths)
          self
        end

        # @param registry [Registry]
        # @return [Array<Store::Objects::Base>]
        def resolve(registry)
          []
        end

        # @param env [Environment]
        def to_rbs_type(env)
          RBS::Types::Bases::Void.new(location: nil)
        end

        # @type () -> RBS::Types::t
        def to_rbs_type_expression
          RBS::Types::Bases::Void.new(location: nil)
        end

        # @return [String]
        def to_s
          'void'
        end
      end
    end
  end
end
