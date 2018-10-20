module BaseModule
  module Long::Long2::Long3
    # @return [String]
    def test_method
      "string"
    end

    # @return [Integer]
    def self.test_singleton_method
      1
    end

    class << self
      # @return [Integer]
      def self.test_singleton_class_method
        1
      end
    end
  end

  class Nested::Nested2
    # @return [String]
    def test_method
      "string"
    end

    # @return [Integer]
    def self.test_singleton_method
      1
    end

    class << self
      # @return [Integer]
      def self.test_singleton_class_method
        1
      end
    end
  end

  class Nested::ChildClass < Nested::Nested2
  end
end
