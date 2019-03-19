module Yoda
  module Typing
    module Tree
      class LiteralWithInterpolation < Base
        def children
          @children ||= node.children.map(&method(:build_child))
        end

        def type
          children.map(&:type)
          case node.type
          when :xstr, :dstr
            generator.string_type
          when :dsym
            generator.symbol_type
          end
        end
      end
    end
  end
end
