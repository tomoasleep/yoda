module Yoda
  module Typing
    module Tree
      class LogicalAssignment < Base
        def children
          @children = node.children.map(&method(:build_child))
        end

        def type
          # TODO
          infer(node.children.last)
        end
      end
    end
  end
end
