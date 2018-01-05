module Yoda
  module Store
    module Types
      class GenericType < Base
        attr_reader :name, :type_arguments

        # @param name [String, Path]
        # @param type_arguments [Array<Base>]
        def initialize(name, type_arguments)
          @name = name
          @type_arguments = type_arguments
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(GenericType) &&
          name == another.name &&
          type_arguments == another.type_arguments
        end

        def hash
          [self.class.name, name, type_arguments].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [GenericType]
        def change_root(namespace)
          self.class.new(Path.new(namespace, name), type_arguments.map { |type| type.change_root(namespace) })
        end

        # @param registry [Registry]
        def resolve(registry)
          registry.find(name)
        end
      end
    end
  end
end
