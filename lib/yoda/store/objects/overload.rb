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
            new(**params.map { |k, v| [k.to_sym, v] }.select { |(k, v)| %i(name tag_list document parameters rbs_function_overload).include?(k) }.to_h)
          end
        end

        # @return [String]
        attr_reader :name

        # @return [Model::FunctionSignatures::ParameterList]
        attr_reader :parameters

        # @return [RbsTypes::FunctionOverload, nil]
        attr_reader :rbs_function_overload

        # @return [String, nil]
        attr_reader :document

        # @return [Array<Tag>]
        attr_reader :tag_list

        # @param name [String]
        # @param parameters [Array<(String, String)>]
        # @param document [String]
        # @param tag_list [Array<Tag>]
        # @param rbs_function_overload [RbsTypes::FunctionOverload, Hash, nil]
        def initialize(name:, parameters: [], document: '', tag_list: [], rbs_function_overload: nil)
          @name = name
          @parameters = Model::FunctionSignatures::ParameterList.new(parameters)
          @document = document
          @tag_list = tag_list
          @rbs_function_overload = rbs_function_overload&.yield_self(&RbsTypes::FunctionOverload.method(:build))
        end

        # @return [Hash]
        def to_h
          { name: name, parameters: parameters.raw_parameters.to_a, document: document, tag_list: tag_list, rbs_function_overload: rbs_function_overload&.to_h }
        end

        # @return [String]
        def to_json(_mode = nil)
          to_h.merge(json_class: self.class.name).to_json
        end
      end
    end
  end
end
