module Yoda
  module Model
    module Parameters
      class Unnamed < Base
        # @return [Symbol]
        def kind
          :unnamed
        end

        # @return [Array<Symbol>]
        def names
          []
        end
      end
    end
  end
end
