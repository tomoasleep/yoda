module Yoda
  module Model
    module TypeExpressions
      class SelfType < Base
        # @param another [Object]
        def eql?(another)
          another.is_a?(SelfType)
        end

        def hash
          [self.class.name].hash
        end

        # @param paths [Array<Path>]
        # @return [self]
        def change_root(paths)
          self
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          fail NotImplementedError
        end

        # @return [String]
        def to_s
          'self'
        end
      end
    end
  end
end
