module Yoda
  module Store
    module Types
      # @abstract
      class Base
        def ==(another)
          eql?(another)
        end

        # @abstract
        # @param namespace [YARD::CodeObjects::Base]
        # @return [Base]
        def change_root(namespace)
          fail NotImplementedError
        end

        # @abstract
        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          fail NotImplementedError
        end

        # @abstract
        # @param registry [Registry]
        # @return [Array<Values::Base>]
        def instanciate(registry)
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def to_s
          fail NotImplementedError
        end
      end
    end
  end
end
