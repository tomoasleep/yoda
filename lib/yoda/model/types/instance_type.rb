module Yoda
  module Model
    module Types
      class InstanceType < Base
        # @return [ScopedPath]
        attr_reader :path

        # @param value [String, Path, ScopedPath]
        def initialize(path)
          @path = ScopedPath.build(path)
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(InstanceType) &&
          path == another.path
        end

        def hash
          [self.class.name, path].hash
        end

        # @param paths [Array<Path>]
        # @return [self]
        def change_root(paths)
          self.class.new(path.change_scope(paths))
        end

        # @param registry [Registry]
        # @return [Array<Store::Objects::Base>]
        def resolve(registry)
          [Store::Query::FindConstant.new(registry).find(path)].compact
        end

        # @return [String]
        def to_s
          path.path.to_s
        end
      end
    end
  end
end
