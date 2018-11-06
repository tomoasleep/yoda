module Yoda
  module Model
    module Parameters
      # @abstract
      class Base
        # @abstract
        # @return [Symbol]
        def kind
          fail NotImplementedError
        end
      end
    end
  end
end
