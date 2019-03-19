module Yoda
  module Typing
    module Tree
      class Begin < Base
        def children
          @children ||= node.children.map(&method(:build_child))
        end

        def type
          children.map(&:type).last
        end
      end
    end
  end
end
