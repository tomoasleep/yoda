module Yoda
  module Store
    module Objects
      class Overload
        class << self
          def json_creatable?
            true
          end

          # @param params [Hash]
          def json_create(params)
            new(**params.map { |k, v| [k.to_sym, v] }.select { |(k, v)| %i(name tag_list document parameters).include?(k) }.to_h)
          end
        end

        # @return [String]
        attr_reader :name

        # @return [Array<(String, String)>]
        attr_reader :parameters

        # @return [String, nil]
        attr_reader :document

        # @return [Array<Tag>]
        attr_reader :tag_list

        # @param name [String]
        # @param parameters [Array<(String, String)>]
        # @param document [String]
        # @param tag_list [Array<Tag>]
        def initialize(name:, parameters: [], document: '', tag_list: [])
          @name = name
          @parameters = parameters
          @document = document
          @tag_list = tag_list
        end

        # @return [Hash]
        def to_h
          { name: name, parameters: parameters, document: document, tag_list: tag_list }
        end

        # @return [String]
        def to_json(_mode = nil)
          to_h.merge(json_class: self.class.name).to_json
        end
      end
    end
  end
end
