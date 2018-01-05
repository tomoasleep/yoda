module Yoda
  module Store
    module Types
      class InstanceType < Base
        attr_reader :name

        VALUE_REGEXP = /\A[0-9a-z]/

        # @param value [String, Path]
        def initialize(name)
          @name = name
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(ConstantType) &&
          name == another.name
        end

        def hash
          [self.class.name, name].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [ConstantType]
        def change_root(namespace)
          self.class.new(Path.new(namespace, name))
        end

        # @param registry [Registry]
        def resolve(registry)
          registry.find(name)
        end
      end
    end
  end
end
