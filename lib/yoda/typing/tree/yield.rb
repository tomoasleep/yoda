module Yoda
  module Typing
    module Tree
      class Yield < Base
        def type
          # TODO
          generator.any_type
        end
      end
    end
  end
end
