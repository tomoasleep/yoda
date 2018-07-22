module Yoda
  module Store
    module Objects
      # @abstract
      class Base
        include Addressable
        include Serializable
        include Patchable

        class << self
          # @return [Array<Symbol>]
          def attr_names
            %i(path document tag_list sources primary_source)
          end
        end

        # @return [String]
        attr_reader :path

        # @return [String]
        attr_reader :document

        # @return [Array<Tag>]
        attr_reader :tag_list

        # @return [Array<(String, Integer, Integer)>]
        attr_reader :sources

        # @return [(String, Integer, Integer), nil]
        attr_reader :primary_source

        # @param path [String]
        # @param document [String]
        # @param tag_list [TagList, nil]
        # @param sources [Array<(String, Integer, Integer)>]
        # @param primary_source [(String, Integer, Integer), nil]
        def initialize(path:, document: '', tag_list: [], sources: [], primary_source: nil, json_class: nil, kind: nil)
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
        def kind
          fail NotImplementedError
        end

        # @return [String]
        def address
          path
        end

        # @return [Hash]
        def to_h
          {
            kind: kind,
            path: path,
            document: document,
            tag_list: tag_list,
            sources: sources,
            primary_source: primary_source
          }
        end

        # @param another [self]
        # @return [self]
        def merge(another)
          self.class.new(merge_attributes(another))
        end

        def hash
          ([self.class.name] + to_h.to_a).hash
        end

        def eql?(another)
          self.class == another.class && to_h == another.to_h
        end

        def ==(another)
          eql?(another)
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
