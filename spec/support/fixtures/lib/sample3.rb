puts 'Hello, World'

module YodaFixture
  class Sample3
    def initialize
    end

    # @param str [String]
    def self.class_method1(str)
      Sample3
    end

    def method1
      Sample3
    end

    def method12
      Sample3.class_method1('')
    end
  end
end
