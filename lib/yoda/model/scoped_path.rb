module Yoda
  module Model
    # ScopedPath represents a path name written in namespaces.
    # ScopedPath owns lexical scopes where the path is written.
    class ScopedPath
      # @return [LexicalContext] represents namespaces in order of nearness.
      attr_reader :scopes
      alias lexical_context scopes

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
        @scopes = LexicalContext.build(scopes)
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

      # @return [Array<Path>]
      def absolute_paths
        scopes.map { |scope| Path.from_names([scope, path]).absolute! }
      end

      # @return [Array<Path>]
      def paths
        scopes.map { |scope| Path.from_names([scope, path]) }
      end
    end
  end
end
