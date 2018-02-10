module Yoda
  module Store
    module Query
      # @abstract
      class Base
        # @return [Registry]
        attr_reader :registry

        # @param registry [Registry]
        def initialize(registry)
          @registry = registry
        end
      end
    end
  end
end
