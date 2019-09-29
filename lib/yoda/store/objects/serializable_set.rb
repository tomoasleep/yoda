module Yoda
  module Store
    module Objects
      class SerializableSet
        include MissingDelegatable
        include Serializable

        delegate_missing :set

        # @return [Set]
        attr_reader :set

        def initialize(els = nil, elements: nil)
          @set = Set.new(els || elements)
        end

        def to_h
          { elements: set.to_a }
        end
      end
    end
  end
end
