module Yoda
  module Store
    module Objects
      class Document
        # @return [String]
        attr_reader :path

        # @return [String]
        attr_reader :document

        # @param path [String]
        # @param document [String]
        def initialize(path, document)
          @path = path
          @document = document
        end
      end
    end
  end
end
