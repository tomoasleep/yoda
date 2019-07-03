module Yoda
  module AST
    class ConstantBaseNode < Node
      # @return [Vnode, nil]
      def base
        nil
      end

      # @return [true, false]
      def absolute?
        true
      end

      # @return [true, false]
      def constant_base?
        true
      end

      def constant?
        true
      end

      # @param location [Location]
      # @return [true, false]
      def just_after_separator?(location)
        return false unless node.location.double_colon
        location == Location.of_ast_location(node.location.double_colon.end)
      end

      # @return [Model::Path]
      def path
        Model::Path.new(path_name)
      end

      # @param base [String, Symbol, nil]
      # @return [String]
      def path_name(base = nil)
        '::'
      end
    end
  end
end
