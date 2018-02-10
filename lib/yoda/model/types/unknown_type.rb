module Yoda
  module Model
    module Types
      class UnknownType < Base
        attr_reader :name

        # @param name [String]
        def initialize(name = 'unknown')
          @name = name
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(UnknownType)
        end

        def hash
          [self.class.name, name].hash
        end

        # @param path [Path]
        # @return [self]
        def change_root(path)
          self
        end

        # @param registry [Registry]
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          []
        end

        # @return [String]
        def to_s
          'any'
        end
      end
    end
  end
end
