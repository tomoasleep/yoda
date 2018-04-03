module Yoda
  module Typing
    class LexicalScope
      # @return [Store::Objects::Base]
      attr_reader :namespace

      # @return [Array<Path>]
      attr_reader :ancestor_paths

      # @param namespace [Store::Objects::Base]
      # @param ancestor_names [Array<Path>]
      def initialize(namespace, ancestor_paths)
        @namespace = namespace
        @ancestor_paths = ancestor_paths
      end

      # @param registry [Store::Registry]
      # @param constant_name [String]
      # @return [Store::Objects::Base, nil]
      def find_constant(registry, constant_name)
        scoped_path = Model::ScopedPath.new(ancestor_paths, constant_name)
        Store::Query::FindConstant.new(registry).find(scoped_path)
      end
    end
  end
end
