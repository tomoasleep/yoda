module Yoda
  module Store
    module Objects
      class Tag
        class << self
          def json_creatable?
            true
          end

          # @param params [Hash]
          def json_create(params)
            new(params.map { |k, v| [k.to_sym, v] }.select { |(k, v)| %i(tag_name name yard_types text).include?(k) }.to_h)
          end
        end

        # @return [String]
        attr_reader :tag_name

        # @return [String, nil]
        attr_reader :name, :text

        # @return [Array<String>]
        attr_reader :yard_types

        # @param tag_name   [String]
        # @param name       [String, nil]
        # @param yard_types [Array<String>]
        # @param text       [String, nil]
        def initialize(tag_name:, name: nil, yard_types: [], text: nil)
          @tag_name = tag_name
          @name = name
          @yard_types = yard_types
          @text = text
        end

        # @return [Hash]
        def to_h
          { name: name, tag_name: tag_name, yard_types: yard_types, text: text }
        end

        # @return [String]
        def to_json
          to_h.merge(json_class: self.class.name).to_json
        end
      end
    end
  end
end
