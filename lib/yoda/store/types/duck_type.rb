module Yoda
  module Store
    module Types
      class DuckType < Base
        attr_reader :method_name

        # @param method_name [String]
        def initialize(method_name)
          @method_name = method_name
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(DuckType) &&
          method_name == another.method_name
        end

        def hash
          [self.class.name, method_name].hash
        end

        # @param namespace [YARD::CodeObjects::Base]
        # @return [DuckType]
        def change_root(namespace)
          self
        end

        # @param registry [Registry]
        def resolve(registry)
          []
        end
      end
    end
  end
end
