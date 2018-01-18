module Yoda
  module Store
    module Types
      class SequenceType < Base
        attr_reader :base_type, :types

        # @param base_type [Base]
        # @param types [Array<Base>]
        def initialize(base_type, types)
          @base_type = base_type
          @types = types
        end

        def name
          base_type.name
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(SequenceType) &&
          base_type  == another.base_type &&
          types == another.types
        end

        def hash
          [self.class.name, name, types].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [SequenceType]
        def change_root(namespace)
          self.class.new(base_type.change_root(namespace), types.map { |type| type.change_root(namespace) })
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base, YARD::CodeObjects::Proxy>]
        def resolve(registry)
          base_type.resolve(registry)
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base, YARD::CodeObjects::Proxy>]
        def instanciate(registry)
          base_type.instanciate(registry)
        end

        # @return [String]
        def to_s
          "#{base_type}(#{types.map(&:to_s).join(', ')})"
        end
      end
    end
  end
end
