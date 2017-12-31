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
      end
    end
  end
end
