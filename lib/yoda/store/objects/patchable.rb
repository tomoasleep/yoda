module Yoda
  module Store
    module Objects
      module Patchable
        # @abstract
        # @return [Symbol]
        def kind
          fail NotImplementedError
        end

        # @abstract
        # @return [Hash]
        def to_h
          fail NotImplementedError
        end
      end
    end
  end
end
