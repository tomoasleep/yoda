module Yoda
  module Typing
    module Tree
      class HashBody < Base
        def type
          infer_hash_node(node)
        end

        # @param node [::AST::Node]
        # @return [Model::TypeExpressions::Base]
        def infer_hash_node(node)
          hash = node.children.each_with_object({}) do |node, memo|
            case node.type
            when :pair
              pair_key, pair_value = node.children
              case pair_key.type
              when :sym
                memo[pair_key.children.first.to_sym] = infer(pair_value)
              when :str
                memo[pair_key.children.first.to_s] = infer(pair_value)
              else
                # TODO: Support other key types.
              end
            when :kwsplat
              content_node = node.children.first
              content_type = infer(content_node)
              # TODO: merge infered result
            end
          end

          Types::AssociativeArray.new(contents: hash)
        end
      end
    end
  end
end
