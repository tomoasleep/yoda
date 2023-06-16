module Yoda
  module Store
    module Objects
      class ValueObject < Base
        class Connected < Base::Connected
          delegate_to_object :value, :rbs_type
        end

        # @return [String]
        attr_reader :value

        # @return [RbsTypes::TypeLiteral, nil]
        attr_reader :rbs_type

        # @return [Array<Symbol>]
        def self.attr_names
          super + %i(value rbs_type)
        end

        # @param path [String]
        # @param value [String]
        def initialize(value: nil, rbs_type: nil, **kwargs)
          super(**kwargs)
          @value = value
          @rbs_type = rbs_type && RbsTypes::TypeLiteral.of(rbs_type)
        end

        # @return [String]
        def name
          @name ||= path.match(MODULE_TAIL_PATTERN) { |md| md[1] || md[2] }
        end

        def kind
          :value
        end

        def to_h
          super.merge(value: value, rbs_type: rbs_type.to_s)
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          super.merge(
            value: another.value || self.value,
            rbs_type: another.rbs_type || self.rbs_type,
          )
        end
      end
    end
  end
end
