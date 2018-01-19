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

      # @param path [String, Symbol, Path]
      # @param code_object [YARD::CodeObject::Base]
      def register(code_object)
        YARD::Registry.register(code_object)
      end

      # @param path [String, Symbol, Path]
      # @param code_object [Symbol, String]
      def at(path)
        if path.is_a?(Symbol)
          YARD::Registry.at(path)
        else
          YARD::Registry.at(path.gsub(/\A::/, ''))
        end
      end

      # @param path [String, Symbol, Path]
      def find(path)
        if path.is_a?(Path)
          YARD::Registry.resolve(path.namespace, path.name.gsub(/\A::/, ''))
        elsif path.is_a?(Symbol)
          at(path)
        else
          at(path.gsub(/\A::/, ''))
        end
      end

      # @param path [String, Symbol, Path]
      # @return [String, Symbol]
      def path_name_of(path)
        if path.is_a?(Path)
          path.name.gsub(/\A::/, '')
        elsif path.is_a?(Symbol)
          path
        else
          path.gsub(/\A::/, '')
        end
      end

      # @param code_object [String, Path]
      # @return [YARD::CodeObjects::Base, YARD::CodeObjects::Proxy]
      def find_or_proxy(path)
        find(path) || YARD::CodeObjects::Proxy.new(YARD::Registry.root, path_name_of(path))
      end
    end
  end
end
