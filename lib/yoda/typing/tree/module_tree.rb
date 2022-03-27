require 'yoda/typing/tree/namespace_inferable'

module Yoda
  module Typing
    module Tree
      class ModuleTree < Base
        include NamespaceInferable

        # @!method node
        #   @return [AST::ModuleNode]

        def infer_type
          infer_namespace
        end
      end
    end
  end
end
