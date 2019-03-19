module Yoda
  module Typing
    module Tree
      class Self < Base
        def type
          context.receiver
        end
      end
    end
  end
end
