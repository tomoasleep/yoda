module Yoda
  module Store
    module Types
      class AnyType < Base
        def eql?(another)
          another.is_a?(AnyType)
        end

        def hash
          [self.class.name].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [AnyType]
        def change_root(namespace)
          self
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          []
        end

        # @param registry [Registry]
        # @return [Array<Values::Base>]
        def instanciate(registry)
          []
        end

        # @return [String]
        def to_s
          value
        end
      end
    end
  end
end
