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

        # @param env [Environment]
        def to_rbs_type(env)
          RBS::Types::Bases::Self.new(location: nil)
        end

        def to_rbs_type_expression
          RBS::Types::Bases::Self.new(location: nil)
        end
      end
    end
  end
end
