module Yoda
  module Model
    module Types
      class AnyType < Base
        def eql?(another)
          another.is_a?(AnyType)
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

        # @return [String]
        def to_s
          'any'
        end
      end
    end
  end
end
