require 'parser'

module YodaFixture
  module Hoge
    class Fuga
      def initialize
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
    end
  end
end
