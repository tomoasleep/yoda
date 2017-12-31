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
    end
  end
end
