module YodaFixture
  class Sample2
    def initialize
    end

    # @param str [String]
    def method1(str)
      str + "hoge"
    end

    # @return [YodaFixture::Sample2]
    def method2
      self
    end

    # @param obj [Sample2]
    # @return [Sample2]
    def method3(obj)
      obj.method2
    end

    def method4
      Sample2
    end

    def method5
      method2
    end

    # @return [Sample2]
    def method6
      Sample2.new
    end
  end
end
