module Yoda
  module Typing
    module Tree
      class Block < Base
        def type
          send_node, arg_node, block_node = node
          infer_send_node(send_node, arg_node, block_node)
        end
      end
    end
  end
end
