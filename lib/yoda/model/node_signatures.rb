module Yoda
  module Model
    module NodeSignatures
      require 'yoda/model/node_signatures/base'
      require 'yoda/model/node_signatures/node'
      require 'yoda/model/node_signatures/send'
      require 'yoda/model/node_signatures/const'

      class << self
        # @param node_info [Typing::NodeInfo]
        # @return [NodeSignatures::Base]
        def for_node_info(node_info)
          signature_type_for_node_info(node_info).new(node_info)
        end

        private

        # @param node_info [Typing::NodeInfo]
        def signature_type_for_node_info(node_info)
          case node_info.kind
          when :send
            Send
          when :const
            Const
          else
            Node
          end
        end
      end
    end
  end
end
