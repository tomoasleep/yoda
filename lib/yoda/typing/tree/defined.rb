module Yoda
  module Typing
    module Tree
      class Escape < Base
        def type
          generator.boolean_type
        end
      end
    end
  end
end
