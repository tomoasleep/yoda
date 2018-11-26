module Yoda
  module Typing
    class Inferencer
      # Bindings of local variables
      class Environment
        # @param parent [Environment, nil]
        # @param binds [Hash{ Symbol => Store::Types::Base}, nil]
        def initialize(parent: nil, binds: nil)
          @parent = parent
          @binds = binds || {}
        end

        # @param key  [String, Symbol]
        def resolve(key)
          @binds[key.to_sym]
        end

        # @param key  [String, Symbol]
        # @param type [Symbol, Store::Types::Base]
        def bind(key, type)
          key = key.to_sym
          type = (type.is_a?(Symbol) && resolve(type)) || type
          @binds.transform_values! { |value| value == key ? type : value }
          @binds[key] = type
          self
        end
      end
    end
  end
end
