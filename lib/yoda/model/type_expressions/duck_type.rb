module Yoda
  module Model
    module TypeExpressions
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

        # @param paths [LexicalContext]
        # @return [self]
        def change_root(paths)
          self
        end

        # @param registry [Registry]
        # @return [Array<Store::Objects::Base>]
        def resolve(registry)
          []
        end

        # @param env [Environment]
        def to_rbs_type(env)
          # TODO: Implement as interface type
          RBS::Types::Bases::Any.new(location: nil)
        end

        # @return [String]
        def to_s
          "##{method_name}"
        end
      end
    end
  end
end
