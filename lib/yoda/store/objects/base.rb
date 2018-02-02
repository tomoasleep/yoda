module Yoda
  module Store
    module Objects
      # @abstract
      class Base
        # @return [String]
        attr_reader :path

        # @return [Document, nil]
        attr_reader :document

        # @return [TagList]
        attr_reader :tag_list

        # @return [Array<(String, Integer, Integer)>]
        attr_reader :sources

        # @return [(String, Integer, Integer), nil]
        attr_reader :primary_source

        # @param path [String]
        # @param document [Document, nil]
        # @param tag_list [TagList, nil]
        # @param sources [Array<(String, Integer, Integer)>]
        # @param primary_source [(String, Integer, Integer), nil]
        def initialize(path:, document: nil, tag_list: nil, sources: [], primary_source: nil, **kwargs)
          @path = path
          @document = document
          @tag_list = tag_list
          @sources = sources
          @primary_source = primary_source
        end

        # @return [String]
        def name
          fail NotImplementedError
        end

        # @return [Symbol]
        def type
          fail NotImplementedError
        end

        # @return [String]
        def address
          path
        end

        # @return [Hash]
        def to_hash
          { path: path, document: document.to_hash, tag_list: tag_list.to_a, sources: sources, primary_source: primary_source }
        end

        # @param another [self]
        # @return [self]
        def merge(another)
          self.class.new(merge_attributes(another))
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          {
            path: path,
            document: document + another.document,
            tag_list: tag_list + another.tag_list,
            sources: sources + another.sources,
            primary_source: primary_source || another.primary_source,
          }
        end
      end
    end
  end
end
