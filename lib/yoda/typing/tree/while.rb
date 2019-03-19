module Yoda
  module Typing
    module Tree
      class While < Base
        def type
          # TODO
          infer(node.children[1])
        end
      end
    end
  end
end
