module Yoda
  module Store
    module Objects
      module RbsTypes
        class FreeVariable
          include Serializable

          # @type (Instance | Hash) -> Instance
          def self.of(type)
            return type if type.is_a?(self)

            build(type)
          end

          # @return [Symbol]
          attr_reader :name

          # @param type [String, Symbol]
          # @param position [ParameterPosition]
          def initialize(name:, position:)
            @name = name.to_sym
            @position = ParameterPosition.of(position)
          end

          # @return [String]
          def to_s
            type
          end

          # @return [Hash]
          def to_h
            {
              name: name,
              position: position.to_h,
            }
          end
        end
      end
    end
  end
end
