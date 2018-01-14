module Yoda
  module Store
    class Path
      attr_reader :namespace, :name

      # @param namespace [YARD::CodeObjects::Base, YARD::CodeObjects::Proxy]
      # @param name [String, Path]
      def initialize(namespace, name)
        fail ArugmentError, namespace unless namespace.is_a?(YARD::CodeObjects::Base) || namespace.is_a?(YARD::CodeObjects::Proxy)
        fail ArugmentError, name unless name.is_a?(String) || name.is_a?(Path)
        @namespace = namespace
        @name = name.is_a?(Path) ? name.name : name
      end

      # @param another [Object]
      def ==(another)
        eql?(another)
      end

      # @param another [Object]
      def eql?(another)
        another.is_a?(Path) &&
        @namespace == another.namespace &&
        @name == another.name
      end

      # @param namespace [YARD::CodeObjects::Base]
      # @return [Path]
      def change_root(new_namespace)
        self.class.new(new_namespace, name)
      end
    end
  end
end
