module Yoda
  module Typing
    module Tree
      class Self < Base
        # @return [Types::Type]
        def infer_type
          context.receiver
        end
      end
    end
  end
end
