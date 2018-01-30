module YodaFixture
  module Namespace1
    class String
      def initialize
      end

      # @param str [::String]
      def method1(str)
        String
      end

      # @param str [::String]
      def method2(str)
        ::String
      end
    end
  end
end
