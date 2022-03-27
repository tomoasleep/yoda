module Yoda
  module Typing
    module Tree
      class ConstantAssignment < Base
        def process
          # TODO
          infer_child(node.content)
        end
      end
    end
  end
end
