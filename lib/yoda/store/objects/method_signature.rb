module Yoda
  module Store
    module Objects
      class MethodSignature
        class << self
          # @param method_object [MethodObject]
          # @return [MethodSignature]
          def from_method_object(method_object)
            new(
              owner: method_object,
              name: method_object.name,
              parameters: method_object.parameters,
              document: method_object.document,
              tag_list: method_object.tag_list,
            )
          end

          # @param method_object [MethodObject]
          # @param overload [Overload]
          # @return [MethodSignature]
          def from_overload(method_object, overload)
            new(
              owner: method_object,
              name: overload.name,
              parameters: overload.parameters,
              document: overload.document,
              tag_list: overload.tag_list,
            )
          end
        end


        # @return [MethodObject]
        attr_reader :owner

        # @return [String]
        attr_reader :name

        # @return [Model::FunctionSignatures::ParameterList]
        attr_reader :parameters

        # @return [String, nil]
        attr_reader :document

        # @return [Array<Tag>]
        attr_reader :tag_list

        # @param owner [MethodObject]
        # @param name [String]
        # @param parameters [Model::FunctionSignature::ParameterList]
        # @param document [String]
        # @param tag_list [Array<Tag>]
        def initialize(owner:, name:, parameters: [], document: '', tag_list: [])
          @name = name
          @parameters = parameters
          @document = document
          @tag_list = tag_list
        end

        # @return [Hash]
        def to_h
          { name: name, parameters: parameters.raw_parameters.to_a, document: document, tag_list: tag_list }
        end

        # @return [String]
        def to_json(_mode = nil)
          to_h.merge(json_class: self.class.name).to_json
        end
      end
    end
  end
end
