module Yoda
  module Typing
    module Tree
      class Const < Base
        def type
          # TODO
          infer(node.children.last)
        end
      end
    end
  end
end
