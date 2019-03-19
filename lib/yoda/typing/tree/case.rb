module Yoda
  module Typing
    module Tree
      class Case < Base
        # @return [[Store::Types::Base, Environment]]
        def infer_case_node
          # TODO
          Types::Union.new([*when_body_nodes, else_node].map { |node| infer(node) })
        end

        def children
          @children ||= [subject, *when_branches, else_branch]
        end

        def subject
          @subject ||= build_child(node.children.first)
        end

        def when_branches
          @when_branches ||= node.children.slice(1, -2).map(&method(:build_child))
        end

        def else_branch
          @else_branch ||= build_child(node.children.last)
        end
      end
    end
  end
end
