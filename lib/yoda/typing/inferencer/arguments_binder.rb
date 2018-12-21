module Yoda
  module Typing
    class Inferencer
      class ArgumentsBinder
        # @return [Types::Generator]
        attr_reader :generator

        # @param generator [Types::Generator]
        def initialize(generator:)
          @generator = generator
        end

        # @param types [Array<Types::Function>]
        # @param arguments [Model::Parameters]
        # @return [Hash{ Symbol => Types::Base }]
        def bind(types:, arguments:)
          binds = types.map { |type| Model::Parameters::Binder.new(arguments).bind(type: type, generator: generator) }
          # @todo Select only one signature to bind arguments
          binds.reduce({}) { |memo, bind| memo.merge!(bind) { |_key, v1, v2| Types::Union.new(v1, v2) } }
        end
      end
    end
  end
end
