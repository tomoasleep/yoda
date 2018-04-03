module Yoda
  module Parsing
    module Scopes
      # Represents root namespace.
      class Root < Base
        def body_nodes
          [node.children.last]
        end

        def kind
          :root
        end

        # @return [String]
        def scope_name
          'Object'
        end
      end
    end
  end
end
