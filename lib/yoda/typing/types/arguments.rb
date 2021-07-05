module Yoda
  module Typing
    module Types
      class Arguments
        # @return [Types::Generator]
        attr_reader :generator

        # @param generator [Types::Generator]
        def from_parameters(generator:)
          @generator = generator
        end

        # @param generator [Types::Generator]
        def initialize(generator:)
          @generator = generator
        end

        # @param types [Array<RBS::MethodType>]
        # @param arguments [Model::Parameters]
        # @return [Hash{ Symbol => Types::Type }]
        def bind(types:, arguments:)
          binds = types.map { |type| ParameterBinder.new(arguments).bind(type: type, generator: generator) }
          # @todo Select only one signature to bind arguments
          binds.reduce({}) { |memo, bind| memo.merge!(bind.to_h) { |_key, v1, v2| generator.union_type(v1, v2) } }
        end
      end
    end
  end
end
