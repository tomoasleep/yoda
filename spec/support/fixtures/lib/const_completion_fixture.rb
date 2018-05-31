module YodaFixture
  class ConstCompletionFixture
    # @param content [String]
    def initialize(content)
      @content = content
      @contents = [content]
    end

    def method1
      ConstCompletionFixture
      ::ConstCompletionFixture
      ::YodaFixture
      YodaFixture::ConstCompletionFixture
      YodaFixture::YodaInnerModule
    end
  end

  module YodaInnerModule
  end
end
