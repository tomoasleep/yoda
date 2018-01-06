require 'yard'

module Yoda
  module Store
    class Registry
      class << self
        # @return [Yoda::Store::Registory]
        def instance
          @instance ||= new
        end
      end

      # @param code_object [YARD::CodeObject::Base]
      def register(code_object)
        YARD::Registry.register(code_object)
      end

      # @param code_object [String]
      def at(path)
        YARD::Registry.at(path)
      end

      # @param path [String, Path]
      def find(path)
        if path.is_a?(Path)
          YARD::Registry.resolve(path.namespace, path.name)
        else
          at(path)
        end
      end

      # @param code_object [String]
      # @return [YARD::CodeObjects::Base, YARD::CodeObjects::Proxy]
      def find_or_proxy(path)
        YARD::Registry.at(path) || YARD::CodeObjects::Proxy.new(YARD::Registry.root, path)
      end
    end
  end
end
