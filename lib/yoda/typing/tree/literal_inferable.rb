module Yoda
  module Typing
    module Tree
      module LiteralInferable
        # @param node [AST::Vnode]
        # @return [Types::Base]
        def infer_literal(node)
          case node.type
          when :dstr, :xstr
            generator.string_type
          when :str, :string
            generator.string_type(node.value.to_s)
          when :dsym
            generator.symbol_type
          when :sym
            generator.symbol_type(node.value.to_sym)
          when :array, :splat
            generator.array_type
          when :hash
            generator.hash_type
          when :irange, :erange
            generator.range_type
          when :regexp
            generator.regexp_type
          when :true
            generator.true_type
          when :false
            generator.false_type
          when :nil
            generator.nil_type
          when :int
            generator.integer_type(node.value.to_i)
          when :float
            generator.float_type
          when :complex
            generator.numeric_type
          when :rational
            generator.numeric_type
          when :empty
            generator.nil_type
          else
            generator.any_type
          end
        end
      end
    end
  end
end
