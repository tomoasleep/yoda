module Yoda
  module Typing
    module Tree
      class Escape < Base
        def type
          # TODO
          node.children[0] ? infer(node.children[0]) : generator.nil_type
        end
      end
    end
  end
end
