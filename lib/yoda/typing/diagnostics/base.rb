module Yoda
  module Typing
    module Diagnostics
      # @abstract
      class Base
        # @return [AST::Node]
        def node
          fail NotImplementedError
        end

        # @return [String]
        def message
          fail NotImplementedError
        end
      end
    end
  end
end
