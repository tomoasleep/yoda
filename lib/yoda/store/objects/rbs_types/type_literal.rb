require 'yoda/store/objects/connected_delegation'

module Yoda
  module Store
    module Objects
      module RbsTypes
        class TypeLiteral
          include Serializable

          # @type (Instance | String) -> Instance
          def self.of(type)
            return type if type.is_a?(self)

            new(type: type)
          end

          # @return [String]
          attr_reader :type

          # @param type [String]
          def initialize(type:)
            @type = type
          end

          # @return [String]
          def to_s
            type
          end

          # @return [Hash]
          def to_h
            {
              type: type,
            }
          end

          # @type () -> RBS::Types::MethodType
          def to_rbs_type
            RBS::Parser.parse_type(type)
          end
        end
      end
    end
  end
end
