module Yoda
  module Store
    module Types
      class Base
        def ==(another)
          eql?(another)
        end
      end
    end
  end
end
