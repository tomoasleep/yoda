module Yoda
  # @abstract
  class BaseError < ::StandardError
  end

  class GemImportError < BaseError
    # @return [String]
    attr_reader :name, :version

    def initialize(name:, version:)
      @name = name
      @version = version
      super(msg)
    end

    def msg
      "Failed to import #{name} #{version}"
    end
  end

  class CoreImportError < BaseError
    # @return [String]
    attr_reader :name

    def initialize(name)
      @name = name
      super(msg)
    end

    def msg
      "Failed to import Ruby #{name} Library"
    end
  end
end
