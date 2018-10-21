module Yoda
  module Model
    module TypeExpressions
      class GenericType < Base
        # @return [Base]
        attr_reader :base_type

        # @return [Array<Base>]
        attr_reader :type_arguments

        # @param base_type  [Base]
        # @param key_type   [Base]
        # @param value_type [Base]
        def self.from_key_value(base_type, key_type, value_type)
          new(base_type, [key_type, value_type])
        end

        # @param paths [Array<Path>]
        # @return [self]
        def change_root(paths)
          self.class.new(base_type.change_root(paths), type_arguments.map { |type| type.change_root(paths) })
        end

        # @param base_type      [TypeExpressions::Base]
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

        def hash
          [self.class.name, base_type, type_arguments].hash
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

        # @return [String]
        def to_s
          "#{base_type}<#{type_arguments.map(&:to_s).join(', ')}>"
        end

        # @return [self]
        def map(&block)
          self.class.new(base_type.map(&block), type_arguments.map(&block))
        end
      end
    end
  end
end
