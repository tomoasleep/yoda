module Yoda
  module Typing
    module Types
      class AssociativeArray < Base
        # @return [::Hash{ String, Symbol => Base }]
        attr_reader :contents

        # @param contents [::Hash{ String, Symbol => Base }]
        def initialize(contents:)
          @contents = contents
        end

        def to_expression
          contents.transform_values(&:to_expression)
        end

        def visilibity
          @self_call ? [:private, :public, :protected] : [:public]
        end

        def to_type_string
          inner = contents.map { |key, value| "#{key} => #{value.to_type_string}"}
          "{#{inner.join(', ')}}"
        end
      end
    end
  end
end
