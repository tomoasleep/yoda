module Yoda
  module Typing
    module Types
      class Union < Base
        # @return [Array<Base>]
        attr_reader :types

        # @param types [Array<Base>]
        # @return [Union, Any, Base]
        def self.new(*types)
          extracted_types = types.map { |type| type.is_a?(Union) ? type.types : type }.flatten
          case extracted_types.length
          when 0
            Any.new
          when 1
            extracted_types.first
          else
            super(*extracted_types)
          end
        end

        # @param types [Array<Base>]
        def initialize(*types)
          types.each { |type| fail TypeError, type unless type.is_a?(Types::Base) }
          @types = types
        end

        def to_expression
          Model::TypeExpressions::UnionType.new(types.map(&:to_expression))
        end

        def to_type_string
          types.map(&:to_type_string).join(" | ")
        end
      end
    end
  end
end
