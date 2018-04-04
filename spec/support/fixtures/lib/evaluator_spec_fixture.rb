module YodaFixture
  class EvaluatorSpecFixture
    # @type String
    attr_reader :content

    # @type Array<String>
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
  end
end
