module Yoda
  module Store
    module Objects
      class ValueObject < Base
        # @return [String]
        attr_reader :value

        # @param path [String]
        # @param value [String]
        def initialize(path:, value: nil, **kwargs)
          super

          @value = value
        end

        # @return [String]
        def name
          @name ||= path.match(MODULE_TAIL_PATTERN) { |md| md[1] || md[2] }
        end

        def type
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
