module YodaFixture
  class ReferenceTagExamples
    def initialize
    end

    # @param x [String]
    # @param y [Integer]
    # @return [String]
    def method1(x, y:)
      x * y
    end

    # @param (see #method1)
    # @return (see #method1)
    def method_with_forward_arg(...)
      method1(...)
    end

    # @param (see #method1)
    # @return (see #method1)
    def method_with_same_args(x, y:)
      method1(x, y: y)
    end

    # @param (see #method1)
    # @return (see #method1)
    def method_with_kw_rest_arg(x, **kwargs)
      method1(x, **kwargs)
    end
  end
end
