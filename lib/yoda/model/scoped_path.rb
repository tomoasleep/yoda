module Yoda
  module Model
    # ScopedPath represents a path name written in namespaces.
    # ScopedPath owns lexical scopes where the path is written.
    class ScopedPath
      # @return [Array<Path>] represents namespaces in order of nearness.
      attr_reader :scopes

      # @return [Path]
      attr_reader :path

      # @param path [Path]
      # @return [ScopedPath]
      def self.build(path)
        path.is_a?(ScopedPath) ? path : ScopedPath.new(['Object'], Path.build(path))
      end

      # @param scopes [Array<Path>] represents namespaces in order of nearness.
      # @param path [Path]
      def initialize(scopes, path)
        @scopes = scopes.map { |pa| Path.build(pa) }
        @path = Path.build(path)
      end

      # @param paths [Array<String, Path>]
      # @return [ScopedPath]
      def change_scope(paths)
        self.class.new(paths, path)
      end

      def hash
        [self.class.name, scopes, path].hash
      end

      def ==(another)
        eql?(another)
      end

      def eql?(another)
        another.is_a?(ScopedPath) && path == another.path && scopes == another.scopes
      end
    end
  end
end
