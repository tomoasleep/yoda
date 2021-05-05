module Yoda
  module Model
    module TypeExpressions
      class AnyType < Base
        def eql?(another)
          another.is_a?(AnyType)
        end

        def hash
          [self.class.name].hash
        end

        # @param paths [LexicalContext]
        # @return [self]
        def change_root(paths)
          self
        end

        # @param registry [Registry]
        # @return [Array<Store::Objects::Base>]
        def resolve(registry)
          []
        end

        def to_rbs_type(_env)
          RBS::Types::Bases::Any.new(location: nil)
        end

        # @return [String]
        def to_s
          'any'
        end
      end
    end
  end
end
