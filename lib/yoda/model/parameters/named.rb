module Yoda
  module Model
    module Parameters
      class Named < Base
        # @return [Symbol]
        attr_reader :name

        # @param name [String, Symbol]
        def initialize(name)
          @name = name.to_sym
        end

        # @return [Symbol]
        def kind
          :named
        end

        # @return [Array<Symbol>]
        def names
          [name]
        end
      end
    end
  end
end
