module Yoda
  module Typing
    module Tree
      class ConstantAssignment < Base
        def infer_type
          # TODO
          infer_child(node.content)
        end
      end
    end
  end
end
