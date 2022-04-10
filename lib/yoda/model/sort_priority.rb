module Yoda
  module Model
    module SortPriority
      # @abstract
      class Base
        def prefix
          fail NotImplementedError
        end
      end

      class High < Base
        def prefix
          "!"
        end
      end

      class Low < Base
        def prefix
          "~"
        end
      end

      class None < Base
        def prefix
          ""
        end
      end

      class << self
        # @return [High]
        def high
          High.new
        end

        # @return [Low]
        def low
          Low.new
        end

        # @return [None]
        def none
          None.new
        end
      end
    end
  end
end
