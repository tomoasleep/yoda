module Yoda
  module Typing
    module Tree
      class HashTree < Base
        # @!method node
        #   @return [AST::HashNode]

        # @return [Types::Type]
        def infer_type
          hash = node.contents.each_with_object({}) do |node, memo|
            case node.type
            when :pair
              case node.key.type
              when :sym
                memo[node.key.value.to_sym] = infer_child(node.value)
              when :str
                memo[node.key.value.to_s] = infer_child(node.value)
              else
                # TODO: Support other key types.
              end
            when :kwsplat
              infer_child(node.content)
              # TODO: merge infered result
            end
          end

          generator.record_type(hash)
        end
      end
    end
  end
end
