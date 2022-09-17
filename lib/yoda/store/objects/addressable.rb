module Yoda
  module Store
    module Objects
      module Addressable
        # @abstract
        # @return [Address]
        def address
          fail NotImplementedError
        end
      end
    end
  end
end
