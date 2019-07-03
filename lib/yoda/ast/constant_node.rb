module Yoda
  module AST
    class ConstantNode < Node
      # @return [Vnode]
      def base
        children[0]
      end

      # @return [Vnode]
      def name
        children[1]
      end

      # @return [true, false]
      def absolute?
        base.absolute?
      end

      # @return [true, false]
      def constant_base?
        false
      end

      def constant?
        true
      end

      # @param location [Parsing::Location]
      # @return [true, false]
      def just_after_separator?(location)
        return false unless source_map.double_colon
        location == Parsing::Location.of_ast_location(source_map.double_colon.end)
      end

      # @return [Model::Path]
      def path
        Model::Path.new(path_name)
      end

      # @param base [String, Symbol, nil]
      # @return [String]
      def path_name(base = nil)
        if base.nil? || base.empty?
          name.name.to_s
        elsif base.constant_base?
          "#{base.path_name}#{name.name}"
        else
          "#{base.path_name}::#{name.name}"
        end
      end
    end
  end
end
