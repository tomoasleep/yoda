module Yoda
  module Store
    module Types
      class GenericType < Base
        attr_reader :base_type, :type_arguments

        # @param base_type  [Base]
        # @param key_type   [Base]
        # @param value_type [Base]
        def self.from_key_value(base_type, key_type, value_type)
          new(base_type, [key_type, value_type])
        end

        # @param base_type      [Types::Base]
        # @param type_arguments [Array<Base>]
        def initialize(base_type, type_arguments)
          @base_type = base_type
          @type_arguments = type_arguments
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(GenericType) &&
          base_type  == another.base_type &&
          type_arguments == another.type_arguments
        end

        def name
          base_type.name
        end

        def hash
          [self.class.name, name, type_arguments].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [GenericType]
        def change_root(namespace)
          self.class.new(base_type.change_root(namespace), type_arguments.map { |type| type.change_root(namespace) })
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base, YARD::CodeObjects::Proxy>]
        def resolve(registry)
          base_type.resolve(registry)
        end

        # @param registry [Registry]
        # @return [Array<Values::Base>]
        def instanciate(registry)
          base_type.instanciate(registry)
        end

        # @return [String]
        def to_s
          "#{base_type}<#{type_arguments.map(&:to_s).join(', ')}>"
        end
      end
    end
  end
end
