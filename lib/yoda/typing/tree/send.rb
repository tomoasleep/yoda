require 'yoda/typing/tree/send_inferable'

module Yoda
  module Typing
    module Tree
      class Send < Base
        include SendInferable

        # @!method node
        #   @return [AST::SendNode]

        # @return [Types::Type]
        def infer_type
          infer_send(node)
        end
      end
    end
  end
end
