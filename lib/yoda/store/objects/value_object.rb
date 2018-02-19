module Yoda
  module Store
    module Objects
      class ValueObject < Base
        # @return [String]
        attr_reader :value

        # @return [Array<Symbol>]
        def self.attr_names
          super + %i(value)
        end

        # @param path [String]
        # @param value [String]
        def initialize(value: nil, **kwargs)
          super(kwargs)
          @value = value
        end

        # @return [String]
        def name
          @name ||= path.match(MODULE_TAIL_PATTERN) { |md| md[1] || md[2] }
        end

        def kind
          :value
        end

        def to_h
          super.merge(value: value)
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          super.merge(
            value: another.value || self.value,
          )
        end
      end
    end
  end
end
