module Yoda
  module Store
    module Types
      class SequenceType < Base
        attr_reader :name, :types

        # @param name [String, Path]
        # @param types [Array<Base>]
        def initialize(name, types)
          @name = name
          @types = types
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(SequenceType) &&
          name == another.name &&
          types == another.types
        end

        def hash
          [self.class.name, name, types].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [SequenceType]
        def change_root(namespace)
          self.class.new(Path.new(namespace, name), types.map { |type| type.change_root(namespace) })
        end

        # @param registry [Registry]
        def resolve(registry)
          registry.find(name)
        end
      end
    end
  end
end
