module YodaFixture
  class EvaluatorSpecFixture
    # @type () -> String
    attr_reader :content

    # @type () -> Array[String]
    attr_reader :contents

    # @param content [String]
    def initialize(content)
      @content = content
      @contents = [content]
    end

    # @param str [String]
    # @return [String]
    def method1(str)
      str + "hoge"
    end

    def method2
      self.method3
    end

    def method3
      self.method1(str)
    end

    # @param param [String]
    def self.smethod1(param)
      self.new(param)
    end

    # @param key1 [Integer]
    # @param key2 [String]
    # @return [Integer]
    def method4(key1:, key2:)
      key1 + key2.to_i
    end

    # @return [Integer]
    def method5
      method4(key1: method4(2, method3), key2: self.method1(content))
    end
  end
end
