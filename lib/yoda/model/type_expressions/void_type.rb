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

        def to_rbs
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
