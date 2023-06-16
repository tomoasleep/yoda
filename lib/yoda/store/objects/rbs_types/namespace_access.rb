require 'yoda/store/objects/connected_delegation'

module Yoda
  module Store
    module Objects
      module RbsTypes
        class NamespaceAccess
          include Serializable

          # @return [Address]
          attr_reader :name

          # @return [Array<Array<TypeLiteral>>]
          attr_reader :args_overloads

          def self.of(param)
            case param
            when NamespaceAccess
              param
            when Hash
              build(**param)
            when String, Symbol
              new(name: param)
            else
              raise ArgumentError, "Unexpected type: #{param.class}"
            end
          end

          # @param name [Symbol]
          # @param args [Array<String>]
          def initialize(
            name:,
            args: [],
            args_overloads: [[]]
          )
            @name = Address.of(name)
            if args.empty?
              @args_overloads = args_overloads.map { |args| args.map(&TypeLiteral.method(:of)) }
            else
              @args_overloads = [args.map(&TypeLiteral.method(:of))]
            end
          end

          # @return [Address]
          def address
            name
          end

          # @param another [NamespaceAccess]
          def merge(another)
            return self if another.nil?
            return another if self == another

            self.class.new(
              name: name,
              args: (args_overloads + another.args_overloads).uniq,
            )
          end

          # @return [Hash]
          def to_h
            {
              name: name.to_s,
              args_overloads: args_overloads.map { |args| args.map(&:to_s) },
            }
          end
        end
      end
    end
  end
end
