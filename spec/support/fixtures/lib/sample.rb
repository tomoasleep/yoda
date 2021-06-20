module YodaFixture
  class Sample
    def initialize
    end

    # @param str [String]
    def method1(str)
      str + "hoge"
    end

    def method2
      self.method3
    end

    def method3
      self.method1(str)
    end

    private

    def method4
      method3
    end
  end
end
