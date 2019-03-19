module Yoda
  module Typing
    module Tree
      class RescueBody < Base
        def type
          # TODO
          infer(node.children[2])
        end
      end
    end
  end
end
