module Yoda
  module Model
    module Parameters
      class Named < Base
        # @return [Symbol]
        attr_reader :name

        # @param name [String, Symbol]
        def initialize(name)
          @name = name
        end

        # @return [Symbol]
        def kind
          :named
        end
      end
    end
  end
end
