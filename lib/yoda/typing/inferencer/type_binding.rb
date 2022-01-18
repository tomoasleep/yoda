module Yoda
  module Typing
    class Inferencer
      # Bindings of local variables
      class TypeBinding
        # @return [TypeBinding, nil]
        attr_reader :parent

        # @return [Hash{ Symbol => Types::Type}]
        attr_reader :binds

        # @param parent [Environment, nil]
        # @param binds [Hash{ Symbol => Types::Type}, nil]
        def initialize(parent: nil, binds: nil)
          @parent = parent
          @binds = (binds || {}).to_h
        end

        # @param key  [String, Symbol]
        def resolve(key)
          all_variables[key.to_sym]
        end

        # @param key  [String, Symbol]
        # @param type [Symbol, Types::Type]
        def bind(key, type)
          key = key.to_sym
          type = (type.is_a?(Symbol) && resolve(type)) || type
          @binds.transform_values! { |value| value == key ? type : value }
          @binds[key] = type
          self
        end

        # @return [Hash{ Symbol => Types::Type }]
        def to_h
          all_variables
        end

        # @return [Hash{ Symbol => Types::Type }]
        def all_variables
          (parent&.all_variables || {}).merge(binds)
        end
      end
    end
  end
end
