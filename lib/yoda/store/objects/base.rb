module Yoda
  module Store
    module Objects
      # @abstract
      class Base
        class << self
          def json_creatable?
            true
          end

          # @param params [Hash]
          def json_create(params)
            new(params.map { |k, v| [k.to_sym, v] }.to_h)
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

        # @return [String]
        def to_json
          to_h.merge(json_class: self.class.name).to_json
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
