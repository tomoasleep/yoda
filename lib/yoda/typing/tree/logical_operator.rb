module Yoda
  module Typing
    module Tree
      class LogicalOperator < Base
        def children
          @children = node.children.map(&method(:build_child))
        end

        def type
          Types::Union.new(node.children.map { |node| infer(node) })
        end
      end
    end
  end
end
