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
            new(**params.map { |k, v| [k.to_sym, v] }.select { |(k, v)| %i(tag_name name yard_types text lexical_scope).include?(k) }.to_h)
          end
        end

        # @return [String]
        attr_reader :tag_name

        # @return [String, nil]
        attr_reader :name, :text

        # @return [Array<String>]
        attr_reader :yard_types, :lexical_scope

        # @return [String, nil]
        attr_reader :option_key, :option_default

        # @param tag_name   [String]
        # @param name       [String, nil]
        # @param yard_types [Array<String>]
        # @param text       [String, nil]
        # @param lexical_scope [Array<String>]
        # @param option_key [String, nil]
        # @param option_default [String, nil]
        def initialize(tag_name:, name: nil, yard_types: [], text: nil, lexical_scope: [], option_key: nil, option_default: nil)
          @tag_name = tag_name
          @name = name
          @yard_types = yard_types
          @text = text
          @lexical_scope = lexical_scope
          @option_key = option_key
          @option_default = option_default
        end

        # @return [Hash]
        def to_h
          { name: name, tag_name: tag_name, yard_types: yard_types, text: text, lexical_scope: lexical_scope, option_key: option_key, option_default: option_default }
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

        # @return [String]
        def to_json(_state = nil)
          to_h.merge(json_class: self.class.name).to_json
        end
      end
    end
  end
end
