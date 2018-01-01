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

      # @param code_object [String]
      def find(path)
        YARD::Registry.at(path)
      end

      # @param code_object [String]
      def find_or_proxy(path)
        YARD::Registry.at(path) || YARD::CodeObjects::Proxy.new(YARD::Registry.root, path)
      end
    end
  end
end
