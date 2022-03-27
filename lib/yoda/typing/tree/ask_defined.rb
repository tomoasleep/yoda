module Yoda
  module Typing
    module Tree
      class AskDefined < Base
        # @return [Types::Type]
        def infer_type
          generator.boolean_type
        end
      end
    end
  end
end
