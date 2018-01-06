module Yoda
  module Store
    module Types
      class UnknownType < Base
        attr_reader :name

        # @param name [String]
        def initialize(name = 'unknown')
          @name = name
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(UnknownType) &&
          name == another.name
        end

        def hash
          [self.class.name, name].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [UnknownType]
        def change_root(namespace)
          self
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          []
        end
      end
    end
  end
end
