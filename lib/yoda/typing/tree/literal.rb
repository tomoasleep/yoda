module Yoda
  module Typing
    module Tree
      class Literal < Base
        def type
          type_for_literal_sexp(node.type)
        end

        # @param sexp_type [::Symbol, nil]
        # @return [Types::Base]
        def type_for_literal_sexp(sexp_type)
          case sexp_type
          when :dstr, :str, :xstr, :string
            generator.string_type
          when :dsym, :sym
            generator.symbol_type
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
            generator.integer_type
          when :float
            generator.float_type
          when :complex
            generator.numeric_type
          when :rational
            generator.numeric_type
          else
            generator.any_type
          end
        end
      end
    end
  end
end
