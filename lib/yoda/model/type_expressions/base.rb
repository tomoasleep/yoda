module Yoda
  module Model
    module TypeExpressions
      # @abstract
      class Base
        def ==(another)
          eql?(another)
        end

        # @abstract
        # @param paths [Array<Path>]
        # @return [Base]
        def change_root(paths)
          fail NotImplementedError
        end

        # @abstract
        # @param registry [Registry]
        # @return [Array<Store::Objects::Base>]
        def resolve(registry)
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def to_s
          fail NotImplementedError
        end

        # @return [Base]
        def map
          yield self
        end
      end
    end
  end
end
