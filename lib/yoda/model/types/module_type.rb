module Yoda
  module Model
    module Types
      class ModuleType < Base
        # @return [ScopedPath]
        attr_reader :path

        # @param value [String, Path, ScopedPath]
        def initialize(path)
          @path = ScopedPath.build(path)
        end

        # @param another [Object]
        def eql?(another)
          another.is_a?(ModuleType) &&
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
        # @return [Array<YARD::CodeObjects::Base>]
        def resolve(registry)
          [Store::Query::FindMetaClass.new(registry).find(path)].compact
        end

        # @return [String]
        def to_s
          "#{path.path.to_s}.module"
        end
      end
    end
  end
end
