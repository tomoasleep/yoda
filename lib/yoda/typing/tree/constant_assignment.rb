module Yoda
  module Typing
    module Tree
      class ConstantAssignment < Base
        def process
          # TODO
          infer(node.children.last)
        end
      end
    end
  end
end
